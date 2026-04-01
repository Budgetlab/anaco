class AddConcordanceRecettesTiersToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :concordance_recettes_tiers, :boolean, default: true
  end
end
