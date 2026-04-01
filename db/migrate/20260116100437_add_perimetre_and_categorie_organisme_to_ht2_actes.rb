class AddPerimetreAndCategorieOrganismeToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :perimetre, :string, null: false, default: 'etat'
    add_column :ht2_actes, :categorie_organisme, :string

    add_index :ht2_actes, :perimetre
  end
end
