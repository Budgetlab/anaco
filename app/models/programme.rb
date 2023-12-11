class Programme < ApplicationRecord
  belongs_to :user

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      unless User.where(nom: row_data['User']).first.nil?
        if Programme.exists?(numero: row_data['Numero'].to_i)
          programme = Programme.where(numero: row_data['Numero'].to_i).first
          programme.update(nom: row_data['Nom'], user_id: User.where(nom: row_data['User']).first.id)
        else
          programme = Programme.new
          programme.user_id = User.where(nom: row_data['User']).first.id
          programme.nom = row_data['Nom']
          programme.numero = row_data['Numero'].to_i
          programme.save
        end
      end
    end
  end
end
