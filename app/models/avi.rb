class Avi < ApplicationRecord
  belongs_to :bop
  belongs_to :user
  # Association vers l'entrée Phase (table de référence du calendrier).
  # Nommée :phase_periode pour ne pas shadow le column string `phase` (legacy)
  # — toutes les comparaisons `avi.phase == 'CRG1'` continuent à fonctionner.
  belongs_to :phase_periode, class_name: 'Phase', foreign_key: 'phase_id',
                             optional: true, inverse_of: :avis
  require 'axlsx'

  MOTIFS_ABSENCE = [
    'Absence de dossier transmis par le RBOP',
    'Dossier transmis tardivement par le RBOP',
    'Dossier incomplet, ne permettant pas de rendre un avis'
  ].freeze

  STATUTS_PAR_PHASE = {
    'programmation initiale' => ['Favorable', 'Favorable avec réserve', 'Défavorable'],
    'services votés'   => ['Favorable', 'Favorable avec réserve', 'Défavorable'],
    'CRG1'             => ['Aucun risque', 'Risques éventuels ou modérés', 'Risques certains ou significatifs'],
    'CRG2'             => ['Aucun risque', 'Risques modérés', 'Risques significatifs']
  }.freeze

  # Liste plate de tous les statuts métier connus (toutes phases + Non reçu transversal).
  # Utilisée par l'admin pour le select unique.
  TOUS_LES_STATUTS = (STATUTS_PAR_PHASE.values.flatten.uniq + ['Non reçu']).freeze

  # Empêche la création d'un avis avec un nom de phase inconnu (ex: 'execution' supprimée,
  # ou typo). Restrict on: :create pour ne pas casser la mise à jour d'avis legacy
  # qui auraient une valeur exotique en base.
  validates :phase, inclusion: { in: Phase::NOMS_CONNUS,
                                  message: "doit être l'un de : #{Phase::NOMS_CONNUS.join(', ')}" },
                    on: :create

  # Règle : 1 avis par (BOP, instance de Phase, année). Empêche les doublons même
  # en cas de POST direct sur create (la garde côté contrôleur ne suffit pas).
  validates :phase_id, uniqueness: { scope: [:bop_id, :annee],
                                      message: 'un avis existe déjà pour ce BOP et cette phase' },
                       if: -> { phase_id.present? }

  before_validation :assigner_phase_periode_depuis_phase_nom
  before_save :set_etat_avis

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1)
    data.each_with_index do |row, idx|
      next if idx == 0

      row_data = Hash[[headers, row].transpose]
      code_bop = row_data['BOP'].to_s
      bop = Bop.find_by(code: code_bop)
      next unless bop

      annee = row_data['Annee'].to_i
      phase = row_data['Phase'].to_s

      avis = Avi.find_or_initialize_by(bop_id: bop.id, annee: annee, phase: phase)
      avis.user_id = bop.user_id
      avis.phase = phase
      avis.annee = annee
      avis.etat = row_data['Etat'].presence || 'Lu'
      avis.statut = row_data['Statut/Risque']
      avis.commentaire = row_data['commentaire']
      avis.motif_absence = row_data["Motif d'absence"]
      avis.avis_recu = (row_data['Statut/Risque'] != 'Non reçu')
      avis.duree_prevision = row_data['Durée prévision'].to_i if row_data['Durée prévision'].present?
      avis.date_reception = parse_date(row_data['Date reception'])
      avis.date_envoi = parse_date(row_data['Date avis initial'])
      avis.is_delai = row_data['Delai'].to_s.strip == 'oui'
      avis.is_crg1 = row_data['CRG1 programmé'].to_s.strip == 'oui'
      avis.ae_i = row_data['AE HT2 alloué']
      avis.cp_i = row_data['CP HT2 alloué']
      avis.t2_i = row_data['AE/CP T2 alloué']
      avis.etpt_i = row_data['ETPT alloué']
      avis.ae_f = row_data['AE HT2 prev']
      avis.cp_f = row_data['CP HT2 prev']
      avis.t2_f = row_data['AE/CP T2 prev']
      avis.etpt_f = row_data['ETPT prev']

      if row_data['Date de saisie'].present?
        avis.created_at = parse_date(row_data['Date de saisie'])
      end

      avis.save
    end
  end

  def self.parse_date(value)
    return nil if value.blank?
    value.is_a?(Date) || value.is_a?(DateTime) ? value : Date.strptime(value.to_s, '%d/%m/%Y')
  rescue ArgumentError
    nil
  end

  # Note : la méthode self.import_execution a été supprimée en juin 2026 (avec les avis
  # phase='execution' qui n'étaient plus utilisés). Si besoin d'importer des données
  # historiques d'exécution, voir l'historique git.

  def self.ransackable_attributes(auth_object = nil)
    ["ae_f", "ae_i", "annee", "avis_recu", "bop_id", "commentaire", "cp_f", "cp_i", "created_at", "date_envoi", "date_reception","duree_prevision", "etat", "etpt_f", "etpt_i", "id", "id_value", "is_crg1", "is_delai", "motif_absence", "phase", "phase_id", "statut", "t2_f", "t2_i", "updated_at", "user_id"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["bop", "phase_periode", "user"]
  end

  private

  # Si phase_id est nul mais (annee + phase) sont renseignés, on lie automatiquement
  # à la Phase correspondante (la première par date_debut s'il y a plusieurs instances
  # du même nom dans l'année). Permet aux callsites legacy de continuer à créer un
  # avis sans connaître la table phases. Pour distinguer SV1/SV2 il faut passer
  # explicitement phase_id (cf. bouton Rédiger du tableau).
  def assigner_phase_periode_depuis_phase_nom
    return if phase_id.present?
    return if annee.blank? || phase.blank?
    matched = Phase.where(annee: annee, nom: phase).order(:date_debut).first
    self.phase_id = matched.id if matched
  end

  # Détermine automatiquement si l'avis doit retomber en Brouillon parce qu'il
  # manque des champs obligatoires. Ne s'applique PAS aux avis non reçus :
  # ceux-ci ont volontairement des champs nuls (date_envoi, statut, etc.) et sont
  # finalisés en "Lu" avec statut="Non reçu" via force_non_recu_attributes!.
  def set_etat_avis
    return if avis_recu == false

    if phase == 'programmation initiale'
      if date_reception.nil? || date_envoi.nil? || statut.nil?
        self.etat = 'Brouillon'
      end
    elsif phase == 'CRG1' || phase == 'CRG2'
      if date_envoi.nil? || statut.nil?
        self.etat = 'Brouillon'
      end
    end
  end
end
