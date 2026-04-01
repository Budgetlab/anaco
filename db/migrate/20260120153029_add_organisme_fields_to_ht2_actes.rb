class AddOrganismeFieldsToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :type_montant, :string, default: 'TTC'
    add_column :ht2_actes, :operation_compte_tiers, :boolean, default: false
    add_column :ht2_actes, :operation_budgetaire, :string
    add_column :ht2_actes, :nature_categorie_organisme, :string
    add_column :ht2_actes, :budget_executoire, :boolean, default: true
  end
end
