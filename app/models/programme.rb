class Programme < ApplicationRecord
  belongs_to :user
  belongs_to :mission
  belongs_to :ministere
  has_many :bops
  has_many :avis, through: :bops
  has_many :gestion_schemas, dependent: :destroy
  has_many :schemas, dependent: :destroy

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      next if User.where(nom: row_data['User']).first.nil?

      ministere = Ministere.find_or_create_by(nom: row_data['Ministère'])
      mission = Mission.find_or_create_by(nom: row_data['Mission'])
      user = User.find_by(nom: row_data['User'])
      deconcentre = row_data['BOP'] == 'oui'
      if Programme.exists?(numero: row_data['Numero'].to_i)
        programme = Programme.where(numero: row_data['Numero'].to_i).first
        programme.update(nom: row_data['Nom'], user_id: user.id, mission_id: mission.id, deconcentre: deconcentre, ministere_id: ministere.id, dotation: row_data['Dotation'], statut: row_data['Statut'])
      else
        programme = Programme.new
        programme.user_id = user.id
        programme.nom = row_data['Nom']
        programme.numero = row_data['Numero'].to_i
        programme.mission_id = mission.id
        programme.ministere_id = ministere.id
        programme.deconcentre = deconcentre
        programme.dotation = row_data['Dotation']
        programme.statut = row_data['Statut']
        programme.save
      end
    end
  end

  def last_schema
    self.schemas&.where(annee: Date.today.year)&.order(created_at: :desc)&.first
  end

  def last_schema_valid
    self.schemas&.where(statut: 'valide')&.order(created_at: :desc)&.first
  end

  def gestion_schemas_empty?
    self.gestion_schemas.empty?
  end

  def avis_remplis_annee(annee)
    self.avis.where(annee: annee).where.not(etat: 'Brouillon').where.not(phase: 'execution')
  end

  def bops_actifs(annee)
    self.bops.where('bops.created_at <= ?', Date.new(annee, 12, 31)).where.not(dotation: 'aucune')
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "mission_id", "nom", "numero", "updated_at", "user_id", "deconcentre", "dotation", "statut", "ministere_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["credits", "user", "bops", "avis", "schemas", "gestion_schemas", "ministere", "mission"]
  end

  ransacker :nom, type: :string do
    Arel.sql("unaccent(programmes.\"nom\")")
  end

  ransacker :numero, type: :string do
    Arel.sql("unaccent(programmes.\"numero\")")
  end

end
