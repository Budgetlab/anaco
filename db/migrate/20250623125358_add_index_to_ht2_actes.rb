class AddIndexToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    # Index composé pour la requête optimisée
    add_index :ht2_actes, [:user_id, :date_cloture, :annee],
              name: 'index_ht2_actes_on_user_cloture_annee'

    # Index pour le tri
    add_index :ht2_actes, [:user_id, :updated_at],
              name: 'index_ht2_actes_on_user_updated_at'

    # Index pour les états (si pas déjà présent)
    add_index :ht2_actes, [:user_id, :etat],
              name: 'index_ht2_actes_on_user_etat'
  end
end
