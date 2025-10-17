class AddDateLimiteToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :date_limite, :date
    add_index :ht2_actes, :date_limite
  end
end
