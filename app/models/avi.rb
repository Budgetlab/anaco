class Avi < ApplicationRecord
  belongs_to :bop
  belongs_to :user
  require 'axlsx'

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1) # get header row
    data.each_with_index do |row, idx|
      next if idx == 0 # skip header

      row_data = Hash[[headers, row].transpose]
      code_bop = row_data['Code BOP'].to_s
      bop = Bop.find_by(code: code_bop)
      next unless bop

      avis = bop.avis.where(phase: 'execution', created_at: Date.new(2023, 1, 1)..Date.new(2023, 12, 31)).first || Avi.new(bop_id: bop.id, user_id: bop.user_id, phase: 'execution')
      column_names_bis = %w[ae_i cp_i t2_i etpt_i ae_f cp_f t2_f etpt_f date_envoi]
      avis.attributes = row_data.slice(*column_names_bis)
      avis.save

    end
  end
end
