class CentreFinancier < ApplicationRecord
  has_and_belongs_to_many :ht2_actes
  belongs_to :programme, optional: true
  belongs_to :bop, optional: true
  # Via le champ direct
  has_many :ht2_actes_principaux,
           class_name: 'Ht2Acte',
           foreign_key: :centre_financier_code,
           primary_key: :code

  scope :non_valide, -> { where(statut: 'non valide') }
  scope :actif, -> { where(statut: 'Actif') }

  def self.ransackable_associations(auth_object = nil)
    ["ht2_actes"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["bop_id", "code", "created_at","deconcentre", "id", "id_value", "updated_at", "programme_id", "statut"]
  end

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      cf = CentreFinancier.find_or_initialize_by(code: row_data['Code'])
      code_bop = row_data['Code'][0..8]
      code_programme = row_data['Code'][1..3]

      bop = Bop.find_by(code: code_bop)
      cf.bop_id = bop.id if bop
      cf.deconcentre = bop.deconcentre if bop
      cf.programme_id = Programme.where(numero: code_programme).pick(:id)
      cf.save
    end
    # on ajouter les programme dans la liste des CF
    Programme.all.each do |programme|
      code = "0#{programme.numero}"
      cf = CentreFinancier.find_or_initialize_by(code: code)
      cf.programme_id = programme.id
      cf.save
    end
  end
end
