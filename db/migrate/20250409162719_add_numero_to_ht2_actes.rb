class AddNumeroToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :numero_utilisateur, :integer
    add_index :ht2_actes, :numero_utilisateur
  end
end
