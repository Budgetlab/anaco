class AddSheetDataToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :sheet_data, :jsonb, default: { data: [] }
  end
end
