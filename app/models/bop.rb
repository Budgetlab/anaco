class Bop < ApplicationRecord
  belongs_to :user
  belongs_to :dcb, class_name: 'User', foreign_key: 'dcb_id'
  has_many :avis, dependent: :destroy
  belongs_to :programme
  has_many :centre_financiers

  def self.import(file)

    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header
      row_data = Hash[[headers, row].transpose]
      # mise à jour des dotations
      #if Bop.find_by(code: row_data['Code'])
      #  bop = Bop.find_by(code: row_data['Code'])
      #  bop.update!(dotation: row_data['Dotation'], created_at: row_data['Created at'].to_datetime)
      #end
      unless User.where(nom: row_data['Identifiant ANACO Contrôleur BOP']).first.nil?
        programme = Programme.find_by(numero: row_data['N°Programme'])
        if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
          @bop = Bop.where(code: row_data['Code CHORUS du BOP'].to_s).first
          @bop.update(user_id: User.where(nom: row_data['Identifiant ANACO Contrôleur BOP']).first.id, dcb_id: User.where(nom: row_data['Identifant DCB Programme ANACO'].to_s).first.id, ministere: row_data['MINISTERE'].to_s, nom_programme: row_data['Libellé programme'].to_s, numero_programme: row_data['N°Programme'].to_i, programme_id: programme.id)
        else
          bop = Bop.new(
            user_id: User.find_by(nom: row_data['Identifiant ANACO Contrôleur BOP'])&.id,
            dcb_id: User.find_by(nom: row_data['Identifant DCB Programme ANACO'].to_s)&.id,
            ministere: row_data['MINISTERE'].to_s,
            nom_programme: row_data['Libellé programme'].to_s,
            numero_programme: row_data['N°Programme'].to_i,
            programme_id: programme.id,
            code: row_data['Code CHORUS du BOP'].to_s,
            created_at: Date.current.beginning_of_year.to_datetime
          )

          # Vérifie que l'objet est valide avant de sauvegarder
          if bop.save
            puts "Bop créé avec succès : #{bop.inspect}"
          else
            puts "Erreur lors de la création du Bop : #{bop.errors.full_messages.join(', ')}"
          end
        end
      end

    end
    Bop.where(dotation: "\n").update_all(dotation: nil)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "dcb", "created_at", "deconcentre","dotation", "id", "id_value", "ministere", "nom_programme", "numero_programme", "updated_at", "user_id", "dcb_id", "programme_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis", "centre_financiers", "dcb", "programme", "user"]
  end
end
