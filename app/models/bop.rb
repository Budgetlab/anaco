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
      programme = Programme.find_by(numero: row_data['N°Programme'])
      user = User.find_by(nom: row_data['Identifiant ANACO Contrôleur BOP'])
      dcb  = User.find_by(nom: row_data['Identifant DCB Programme ANACO'].to_s)
      deconcentre = row_data['Déconcentré'].to_s.strip.downcase == 'oui'
      dotation = row_data['Dotation'].presence
      statut = row_data['Statut'].to_s.strip.downcase.presence_in(['actif', 'inactif']) || 'actif'

      next if user.nil? || programme.nil?

      if Bop.exists?(code: row_data['Code CHORUS du BOP'].to_s)
        @bop = Bop.find_by(code: row_data['Code CHORUS du BOP'].to_s)
        @bop.update(user_id: user.id, dcb_id: dcb&.id, programme_id: programme.id,
                    dotation: dotation, deconcentre: deconcentre, statut: statut)
      else
        bop = Bop.new(
          user_id: user.id,
          dcb_id: dcb&.id,
          programme_id: programme.id,
          code: row_data['Code CHORUS du BOP'].to_s,
          dotation: dotation,
          deconcentre: deconcentre,
          statut: statut,
          created_at: Date.current.beginning_of_year.to_datetime
        )

        unless bop.save
          puts "Erreur lors de la création du Bop : #{bop.errors.full_messages.join(', ')}"
        end
      end

    end
    Bop.where(dotation: "\n").update_all(dotation: nil)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "dcb", "created_at", "deconcentre", "dotation", "id", "id_value", "updated_at", "user_id", "dcb_id", "programme_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avis", "centre_financiers", "dcb", "programme", "user"]
  end
end
