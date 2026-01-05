class AddPdfGenerationStatusToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :pdf_generation_status, :string, default: 'none'
  end
end
