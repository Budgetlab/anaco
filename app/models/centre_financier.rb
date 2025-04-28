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
      next if CentreFinancier.exists?(code: row_data['Code'])

      cf = CentreFinancier.new
      cf.code = row_data['Code']

      bop = Bop.find_by(code: row_data['Code'][0..8])
      cf.bop_id = bop.id if bop
      programme = Programme.find_by(numero: row_data['Code'][1..3])
      cf.programme_id = programme.id if programme
      cf.save
    end
    Programme.all.each do |programme|
      code = "0#{programme.numero}"
      next if CentreFinancier.exists?(code: code)

      cf = CentreFinancier.new
      cf.code = code
      cf.programme_id = programme.id
      cf.save
    end
  end
end
