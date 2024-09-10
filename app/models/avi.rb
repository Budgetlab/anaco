class Avi < ApplicationRecord
  belongs_to :bop
  belongs_to :user
  require 'axlsx'

  # fonction pour importer les avis d'exécution
  def self.import(file)
    Avi.where(phase: 'execution').destroy_all
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      code_bop = row_data['Code BOP'].to_s
      bop = Bop.find_by(code: code_bop)
      next unless bop

      avis = Avi.where(bop_id: bop.id, user_id: bop.user_id, phase: row_data['phase'], annee: 2023).first || Avi.new(bop_id: bop.id, user_id: bop.user_id, phase: row_data['phase'], annee: 2023)
      # avis = bop.avis.find_or_initialize_by(phase: row_data['phase'], annee: 2023)

      column_names_bis = row_data['phase'] == 'execution' ? %w[ae_f cp_f t2_f etpt_f] : %w[created_at etat date_reception date_envoi statut ae_i cp_i t2_i etpt_i ae_f cp_f t2_f etpt_f commentaire]
      avis.attributes = row_data.slice(*column_names_bis)

      if row_data['phase'] == 'début de gestion'
        avis.is_crg1 = row_data['is_crg1'] == 'oui' ? true : false
        avis.is_delai = row_data['is_delai'] == 'oui' ? true : false
      end
      if row_data['phase'] == 'execution'
        avis_debut_n1 = bop.avis.where(phase: 'début de gestion', annee: 2023).first
        avis.ae_f = row_data['ae_f'].to_f.round(1)
        avis.cp_f = row_data['cp_f'].to_f.round(1)
        avis.t2_f = row_data['t2_f'].to_f.round(1)
        avis.etpt_f = row_data['etpt_f'].to_f.round(1)
        avis.ae_i = avis_debut_n1&.ae_i || 0
        avis.cp_i = avis_debut_n1&.cp_i || 0
        avis.t2_i = avis_debut_n1&.t2_i || 0
        avis.etpt_i = avis_debut_n1&.etpt_i || 0
        avis.date_envoi = Date.new(2024, 1, 1)
      end
      avis.save
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["ae_f", "ae_i", "annee", "bop_id", "commentaire", "cp_f", "cp_i", "created_at", "date_envoi", "date_reception", "etat", "etpt_f", "etpt_i", "id", "id_value", "is_crg1", "is_delai", "phase", "statut", "t2_f", "t2_i", "updated_at", "user_id"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["bop", "user"]
  end
end
