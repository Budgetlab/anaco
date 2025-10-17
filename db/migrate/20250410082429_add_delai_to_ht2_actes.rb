class AddDelaiToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :delai_traitement, :integer
    add_index :ht2_actes, :delai_traitement
  end
end
