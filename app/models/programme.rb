class Programme < ApplicationRecord
  belongs_to :user
  has_many :credits, dependent: :destroy
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
      unless User.where(nom: row_data['User']).first.nil?
        ministere = Ministere.find_or_create_by(nom: row_data['Ministère'])
        mission = Mission.find_or_create_by(nom: row_data['Mission'], ministere_id: ministere.id)
        user = User.find_by(nom: row_data['User'])
        deconcentre = row_data['BOP'] == "oui" ? true : false
        if Programme.exists?(numero: row_data['Numero'].to_i)
          programme = Programme.where(numero: row_data['Numero'].to_i).first
          programme.update(nom: row_data['Nom'], user_id: user.id, mission_id: mission.id, deconcentre: deconcentre)
        else
          programme = Programme.new
          programme.user_id = user.id
          programme.nom = row_data['Nom']
          programme.numero = row_data['Numero'].to_i
          programme.mission_id = mission.id
          programme.deconcentre = deconcentre
          programme.save
        end
      end
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "mission_id", "nom", "numero", "updated_at", "user_id", "deconcentre", "dotation"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["credits", "user", "bops", "avis", "schemas", "gestion_schemas"]
  end
end
