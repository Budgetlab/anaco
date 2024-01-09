class Bop < ApplicationRecord
  belongs_to :user
  has_many :avis, dependent: :destroy

  def self.import(file)

    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      unless User.where(nom: row_data['Identifiant']).first.nil?
        if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
          @bop = Bop.where(code: row_data['Code CHORUS du BOP'].to_s).first
          @bop.update(user_id: User.where(nom: row_data['Identifiant']).first.id, consultant: User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id, ministere: row_data['MINISTERE'].to_s, nom_programme: row_data['Libellé programme'].to_s, numero_programme: row_data['N°Programme'].to_i )
        else
          bop = Bop.new
          bop.user_id = User.where(nom: row_data['Identifiant']).first.id
          bop.consultant = User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id
          bop.ministere = row_data['MINISTERE'].to_s
          bop.nom_programme = row_data['Libellé programme'].to_s
          bop.numero_programme = row_data['N°Programme'].to_i
          bop.code = row_data['Code CHORUS du BOP'].to_s
          bop.created_at = Date.new(2024, 1, 1)
          bop.save
       	end
      end


    end
    end
end
