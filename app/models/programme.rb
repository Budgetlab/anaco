class Programme < ApplicationRecord
  belongs_to :user
  has_many :credits, dependent: :destroy

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      puts row_data
      puts "ok"
      unless User.where(nom: row_data['User']).first.nil?
        puts "k"
        ministere = Ministere.find_or_create_by(nom: row_data['Ministère'])
        mission = Mission.find_or_create_by(nom: row_data['Mission'], ministere_id: ministere.id)
        user = User.find_by(nom: row_data['User'])
        if Programme.exists?(numero: row_data['Numero'].to_i)
          programme = Programme.where(numero: row_data['Numero'].to_i).first
          programme.update(nom: row_data['Nom'], user_id: user.id, mission_id: mission.id)
        else
          programme = Programme.new
          programme.user_id = user.id
          programme.nom = row_data['Nom']
          programme.numero = row_data['Numero'].to_i
          programme.mission_id = mission.id
          programme.save
        end
      end
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "id_value", "mission_id", "nom", "numero", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["credits", "user"]
  end
end
