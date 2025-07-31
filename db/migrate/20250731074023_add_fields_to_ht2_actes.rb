class AddFieldsToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :categorie, :string
    add_column :ht2_actes, :numero_marche, :string
    add_column :ht2_actes, :services_votes, :boolean, default: false
    remove_column :ht2_actes, :complexite
  end
end
