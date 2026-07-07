class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :bops
  has_many :consulted_bops, class_name: 'Bop', foreign_key: 'dcb_id'
  has_many :avis
  has_many :programmes
  has_many :gestion_schemas
  has_many :schemas
  has_many :actes
  has_many :organismes

  # fonction d'import des utilisateurs dans la bdd
  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      user = User.find_or_initialize_by(nom: row_data['nom'].to_s)
      user.email = "user#{idx.to_s}@finances.gouv.fr"
      user.statut = row_data['statut'].to_s
      user.nom = row_data['nom'].to_s
      user.password = row_data['Mot de passe'].to_s
      user.save
      puts "Failed to save user: #{user.errors.full_messages.join(', ')}"
    end
  end

  def self.authentication_keys
    { statut: true, nom: false }
  end

  def self.ransackable_associations(auth_object = nil)
    ["actes", "avis", "bops", "consulted_bops", "gestion_schemas", "organismes", "programmes", "schemas"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ['created_at', 'email', 'encrypted_password', 'id', 'id_value', 'nom', 'remember_created_at', 'reset_password_sent_at', 'reset_password_token', 'statut', 'updated_at']
  end

  def programmes_with_schemas(annee)
    self.programmes.left_outer_joins(:schemas).where(schemas: { annee: annee, statut: 'valide' }).distinct.count
  end

  def bops_with_avis(annee, phase)
    self.bops.left_outer_joins(:avis).where(avis: { phase: phase, annee: annee, etat: ['Lu', 'En attente de lecture'] }).count
  end

  def bops_with_crg1(annee)
    self.bops.left_outer_joins(:avis).where(avis: { annee: annee, etat: ['Lu', 'En attente de lecture'], phase: 'programmation initiale', is_crg1: true }).count
  end

  def bops_actifs(annee)
    self.bops.actifs_en(annee)
  end

  def bops_inactifs(annee)
    self.bops.inactifs_en(annee)
  end

  # Nombre total d'avis à produire pour l'année : tag "À rédiger" (pas d'avis) + "Brouillon",
  # toutes phases confondues, en cohérence avec les badges du tableau remplissage_avis.
  # Le calendrier est lu depuis la table phases : si une phase n'existe pas dans
  # l'année (ex: SV en 2024), elle n'est pas comptée. Si elle existe mais date_debut
  # est dans le futur, elle est non ouverte et n'est pas comptée non plus.
  # - SV    : 1 par BOP si dernier avis SV manquant ou en brouillon (et phase ouverte)
  # - Début : 1 par BOP si avis début manquant ou en brouillon (et phase ouverte)
  # - CRG1  : 1 par BOP si avis CRG1 manquant ou en brouillon, sauf si début.is_crg1 == false
  #           (cas N/A : le CRG1 n'est pas programmé). Quand début est nil, on compte.
  # - CRG2  : 1 par BOP si avis CRG2 manquant ou en brouillon (et phase ouverte)
  def avis_a_remplir(annee, reference_date = Date.today)
    # Une phase nommée X est ouverte pour l'année si au moins une de ses instances
    # a une date_debut <= reference_date.
    phases_ouvertes_noms = Phase.pour_annee(annee)
                                .where('date_debut <= ?', reference_date)
                                .pluck(:nom).uniq.to_set

    bops_ids     = bops_actifs(annee).pluck(:id)
    avis_par_bop = self.avis.where(annee: annee, bop_id: bops_ids).group_by(&:bop_id)

    bops_ids.sum do |bop_id|
      avis_bop = avis_par_bop[bop_id] || []
      sv    = avis_bop.select { |a| a.phase == 'services votés' }.max_by(&:created_at)
      debut = avis_bop.find { |a| a.phase == 'programmation initiale' }
      crg1  = avis_bop.find { |a| a.phase == 'CRG1' }
      crg2  = avis_bop.find { |a| a.phase == 'CRG2' }

      count = 0
      count += 1 if phases_ouvertes_noms.include?('services votés')   && (sv.nil?    || sv.etat    == 'Brouillon')
      count += 1 if phases_ouvertes_noms.include?('programmation initiale') && (debut.nil? || debut.etat == 'Brouillon')
      count += 1 if phases_ouvertes_noms.include?('CRG1')             && debut&.is_crg1 != false && (crg1.nil? || crg1.etat == 'Brouillon')
      count += 1 if phases_ouvertes_noms.include?('CRG2')             && (crg2.nil?  || crg2.etat  == 'Brouillon')
      count
    end
  end

  def avis_a_remplir_phase(annee, phase)
    case phase
    when 'CRG1'
      self.avis.where(annee: annee, phase: 'programmation initiale', is_crg1: true).where.not(etat: 'Brouillon').count
    else
      bops_actifs(annee).count
    end
  end

  def avis_remplis(annee, phase)
    self.avis.where(annee: annee, phase: phase).where.not(etat: 'Brouillon').count
  end

  def avis_remplis_annee(annee)
    self.avis.where(annee: annee).where.not(etat: 'Brouillon')
  end

  def avis_brouillon(annee, phase)
    self.avis.where(annee: annee, phase: phase).where(etat: 'Brouillon').count
  end

  def taux_de_remplissage(annee, phase)
    if avis_a_remplir_phase(annee, phase).zero?
      100
    else
      ((avis_remplis(annee, phase)* 100.0 / avis_a_remplir_phase(annee, phase)).to_f ).round
    end
  end

  # BOPs que l'utilisateur consulte (en tant que DCB) en excluant ceux dont il est lui-même CBR.
  # Sert de périmètre pour la page de consultation et update_etat (autorisation).
  def bops_a_consulter
    consulted_bops.where.not(user_id: id)
  end

  def avis_a_lire_recus(annee, phase)
    bops_a_consulter.joins(:avis).where('avis.phase': phase, 'avis.annee': annee).where.not('avis.etat': 'Brouillon').count
  end

  def avis_a_lire
    bops_a_consulter.joins(:avis).where('avis.etat': 'En attente de lecture').count
  end

  def avis_lus(annee, phase)
    bops_a_consulter.joins(:avis).where('avis.etat': 'Lu', 'avis.phase': phase, 'avis.annee': annee).count
  end

  def taux_de_lecture(annee, phase)
    if avis_a_lire_recus(annee, phase).zero?
      100
    else
      ((avis_lus(annee, phase)*100.0/avis_a_lire_recus(annee, phase)).to_f).round
    end
  end

  # ─── Variantes par INSTANCE de phase (objet Phase, filtre sur phase_id) ───────
  # Pour la page suivi_remplissage : un onglet par phase existante (SV1, SV2, …).

  def avis_a_remplir_phase_instance(annee, phase)
    if phase.nom == 'CRG1'
      self.avis.where(annee: annee, phase: 'programmation initiale', is_crg1: true).where.not(etat: 'Brouillon').count
    else
      bops_actifs(annee).count
    end
  end

  def avis_remplis_instance(phase)
    self.avis.where(phase_id: phase.id).where.not(etat: 'Brouillon').count
  end

  def avis_brouillon_instance(phase)
    self.avis.where(phase_id: phase.id, etat: 'Brouillon').count
  end

  def taux_de_remplissage_instance(annee, phase)
    a_remplir = avis_a_remplir_phase_instance(annee, phase)
    return 100 if a_remplir.zero?

    ((avis_remplis_instance(phase) * 100.0 / a_remplir).to_f).round
  end

  def avis_a_lire_recus_instance(phase)
    bops_a_consulter.joins(:avis).where('avis.phase_id': phase.id).where.not('avis.etat': 'Brouillon').count
  end

  def avis_lus_instance(phase)
    bops_a_consulter.joins(:avis).where('avis.etat': 'Lu', 'avis.phase_id': phase.id).count
  end

  def taux_de_lecture_instance(phase)
    recus = avis_a_lire_recus_instance(phase)
    return 100 if recus.zero?

    ((avis_lus_instance(phase) * 100.0 / recus).to_f).round
  end

  def programmes_access
    Programme.where(id: self.bops.pluck(:programme_id).uniq)
  end

end
