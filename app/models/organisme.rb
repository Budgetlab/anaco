class Organisme < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :ht2_actes

  validates :nom, presence: true
  validates :id_opera, uniqueness: true, allow_nil: true

  scope :actif, -> { where(statut: 'actif') }
  scope :inactif, -> { where(statut: 'inactif') }

  def self.ransackable_associations(auth_object = nil)
    ["ht2_actes", "user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["acronyme", "created_at", "id", "id_opera", "nom", "statut", "updated_at", "user_id"]
  end

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]

      user = User.find_by(nom: row_data['Nom ANACO']&.to_s&.strip)
      next unless user

      id_opera = row_data['ID Opera'].present? ? row_data['ID Opera'].to_i : nil
      statut   = row_data['Statut']&.to_s&.strip

      organisme = Organisme.find_by(id_opera: id_opera) if id_opera

      if organisme.nil?
        next unless statut&.downcase == 'actif'
        organisme = Organisme.new(id_opera: id_opera)
      end

      organisme.user_id = user.id
      organisme.nom = row_data['Nom']&.to_s&.strip
      organisme.acronyme = row_data['Acronyme']&.to_s&.strip
      organisme.statut = statut if statut.present?
      organisme.nature_controle = row_data['Nature de contrôle']

      organisme.save
    end
  end
end
