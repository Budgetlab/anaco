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

        # BOP déjà flagués 'inactif' → fin d'activité positionnée au 1er janvier de l'année
        # de updated_at. La date est exclusive : ainsi le BOP est inactif dès cette année-là.
        # Best effort à ajuster manuellement après migration si nécessaire.
        execute <<~SQL
          UPDATE bops
          SET date_fin_activite = make_date(EXTRACT(YEAR FROM updated_at)::int, 1, 1)
          WHERE statut = 'inactif' AND date_fin_activite IS NULL;
        SQL
      end
    end
  end
end
