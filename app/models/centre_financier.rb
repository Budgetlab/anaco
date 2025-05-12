class CentreFinancier < ApplicationRecord
  has_and_belongs_to_many :ht2_actes
  belongs_to :programme, optional: true
  belongs_to :bop, optional: true

  def self.ransackable_associations(auth_object = nil)
    ["ht2_actes"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["bop_id", "code", "created_at", "id", "id_value", "updated_at", "programme_id"]
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

      cf.bop_id = Bop.where(code: code_bop).pick(:id)
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
