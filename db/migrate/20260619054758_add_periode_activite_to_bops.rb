class AddPeriodeActiviteToBops < ActiveRecord::Migration[8.1]
  def change
    add_column :bops, :date_debut_activite, :date
    add_column :bops, :date_fin_activite, :date
    add_index :bops, [:date_debut_activite, :date_fin_activite],
              name: 'index_bops_on_periode_activite'

    reversible do |dir|
      dir.up do
        # Backfill : date_debut_activite ← created_at (date métier la plus proche dispo).
        execute <<~SQL
          UPDATE bops
          SET date_debut_activite = created_at::date
          WHERE date_debut_activite IS NULL;
        SQL

        # BOP déjà flagués 'inactif' → fin d'activité positionnée à updated_at (best effort
        # à ajuster manuellement après migration si nécessaire).
        execute <<~SQL
          UPDATE bops
          SET date_fin_activite = updated_at::date
          WHERE statut = 'inactif' AND date_fin_activite IS NULL;
        SQL
      end
    end
  end
end
