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

  # fonction d'import des utilisateurs dans la bdd
  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      user = User.find_or_initialize_by(nom: row_data['nom'].to_s)
      user.email = user.email
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
    ['avis', 'bops', 'consulted_bops', 'credits', 'programmes', 'schemas', 'gestion_schemas']
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
    self.bops.left_outer_joins(:avis).where(avis: { annee: annee, etat: ['Lu', 'En attente de lecture'], phase: 'début de gestion', is_crg1: true }).count
  end

  def bops_actifs(annee)
    self.bops.where('bops.created_at <= ?', Date.new(annee, 12, 31)).where(dotation: ['HT2','T2','HT2 et T2','', nil])
  end

  def bops_inactifs(annee)
    self.bops.where('bops.created_at <= ?', Date.new(annee, 12, 31)).where(dotation: 'aucune')
  end

  def avis_a_remplir(annee, phase)
    case phase
    when 'début de gestion'
      bops_actifs(annee).count - bops_with_avis(annee, phase)
    when 'CRG1'
      avis_a_remplir(annee, 'début de gestion') + bops_with_crg1(annee) - bops_with_avis(annee, phase)
    when 'CRG2'
      avis_a_remplir(annee, 'début de gestion') + avis_a_remplir(annee, 'CRG1') + bops_actifs(annee).count - bops_with_avis(annee, phase)
    end
  end

  def avis_a_remplir_phase(annee, phase)
    case phase
    when 'CRG1'
      self.avis.where(annee: annee, phase: 'début de gestion', is_crg1: true).where.not(etat: 'Brouillon').count
    else
      bops_actifs(annee).count
    end
  end

  def avis_remplis(annee, phase)
    self.avis.where(annee: annee, phase: phase).where.not(etat: 'Brouillon').count
  end

  def avis_remplis_annee(annee)
    self.avis.where(annee: annee).where.not(etat: 'Brouillon').where.not(phase: 'execution')
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

  def avis_a_lire_recus(annee, phase)
    self.consulted_bops.where.not(user_id: self.id).joins(:avis).where('avis.phase': phase, 'avis.annee': annee).where.not('avis.etat': 'Brouillon').count
  end

  def avis_a_lire
    self.consulted_bops.where.not(user_id: self.id).joins(:avis).where('avis.etat': 'En attente de lecture').count
  end

  def avis_lus(annee, phase)
    self.consulted_bops.where.not(user_id: self.id).joins(:avis).where('avis.etat': 'Lu', 'avis.phase': phase, 'avis.annee': annee).count
  end

  def taux_de_lecture(annee, phase)
    if avis_a_lire_recus(annee, phase).zero?
      100
    else
      ((avis_lus(annee, phase)*100.0/avis_a_lire_recus(annee, phase)).to_f).round
    end
  end

  def programmes_access
    Programme.where(id: self.bops.pluck(:programme_id).uniq)
  end

end
