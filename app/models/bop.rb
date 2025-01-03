class Bop < ApplicationRecord
  belongs_to :user
  belongs_to :dcb, class_name: 'User', foreign_key: 'dcb_id'
  has_many :avis, dependent: :destroy
  belongs_to :programme

  def self.import(file)

    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      #mise à jour des dotations
      if Bop.find_by(code: row_data['Code'])
        bop = Bop.find_by(code: row_data['Code'])
        bop.update!(dotation: row_data['Dotation'], created_at: row_data['Created at'].to_datetime)
      end
      unless User.where(nom: row_data['Identifiant']).first.nil?
        if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
          @bop = Bop.where(code: row_data['Code CHORUS du BOP'].to_s).first
          @bop.update(user_id: User.where(nom: row_data['Identifiant']).first.id, dcb_id: User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id, ministere: row_data['MINISTERE'].to_s, nom_programme: row_data['Libellé programme'].to_s, numero_programme: row_data['N°Programme'].to_i)
        else
          bop = Bop.new
          bop.user_id = User.where(nom: row_data['Identifiant']).first.id
          bop.dcb_id = User.where(nom: row_data['DCB en consultation sur le programme'].to_s).first.id
          bop.ministere = row_data['MINISTERE'].to_s
          bop.nom_programme = row_data['Libellé programme'].to_s
          bop.numero_programme = row_data['N°Programme'].to_i
          bop.code = row_data['Code CHORUS du BOP'].to_s
          bop.created_at = Date.new(Date.today.year, 1, 1)
          bop.save
        end
      end

    end
    Bop.where(dotation: "\n").update_all(dotation: nil)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "dcb", "created_at", "dotation", "id", "id_value", "ministere", "nom_programme", "numero_programme", "updated_at", "user_id", "dcb_id", "programme_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis", "user", "programme", "dcb"]
  end
end
