class AddDotationToBop < ActiveRecord::Migration[7.0]
  def change
    add_column :bops, :dotation, :string
  end
end
