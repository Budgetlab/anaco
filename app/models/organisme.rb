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

      # Find or initialize organisme by nom
      organisme = Organisme.find_or_initialize_by(nom: row_data['Nom']&.to_s&.strip)

      # Find user by nom
      user = User.find_by(nom: row_data['Nom user']&.to_s&.strip) if row_data['Nom user'].present?

      organisme.acronyme = row_data['Acronyme']&.to_s&.strip if row_data['Acronyme'].present?
      organisme.statut = row_data['Statut']&.to_s&.strip if row_data['Statut'].present?
      organisme.user_id = user.id if user.present?
      organisme.id_opera = row_data['Id opera']&.to_i if row_data['Id opera'].present?

      organisme.save
    end
  end
end
