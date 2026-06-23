class CreatePhases < ActiveRecord::Migration[8.1]
  def change
    create_table :phases do |t|
      t.string :nom, null: false
      t.integer :annee, null: false
      t.date :date_debut, null: false
      t.timestamps
    end

    # Empêche les doublons exacts (ex: 2 phases CRG1 avec même date_debut en 2026).
    add_index :phases, [:annee, :nom, :date_debut], unique: true,
              name: 'index_phases_unique_par_annee_nom_debut'
    # Index d'ordonnancement (utilisé par numero_dans_annee et le rendu du tableau).
    add_index :phases, [:annee, :date_debut],
              name: 'index_phases_on_annee_and_date_debut'

    # Seed initial : phases connues 2024 / 2025 / 2026.
    reversible do |dir|
      dir.up do
        seed = [
          # 2023 : pas de services votés (phase non existante cette année-là)
          { nom: 'début de gestion', annee: 2023, date_debut: '2023-01-01' },
          { nom: 'CRG1',             annee: 2023, date_debut: '2023-06-01' },
          { nom: 'CRG2',             annee: 2023, date_debut: '2023-09-01' },
          # 2024 : pas de services votés (phase non existante cette année-là)
          { nom: 'début de gestion', annee: 2024, date_debut: '2024-01-01' },
          { nom: 'CRG1',             annee: 2024, date_debut: '2024-06-01' },
          { nom: 'CRG2',             annee: 2024, date_debut: '2024-09-01' },
          # 2025
          { nom: 'services votés',   annee: 2025, date_debut: '2025-01-01' },
          { nom: 'début de gestion', annee: 2025, date_debut: '2025-02-20' },
          { nom: 'CRG1',             annee: 2025, date_debut: '2025-06-01' },
          { nom: 'CRG2',             annee: 2025, date_debut: '2025-09-01' },
          # 2026
          { nom: 'services votés',   annee: 2026, date_debut: '2026-01-01' },
          { nom: 'début de gestion', annee: 2026, date_debut: '2026-02-20' },
          { nom: 'CRG1',             annee: 2026, date_debut: '2026-06-01' },
          { nom: 'CRG2',             annee: 2026, date_debut: '2026-09-01' }
        ]
        now = Time.current.iso8601
        rows = seed.map { |r| "('#{r[:nom].gsub("'", "''")}', #{r[:annee]}, '#{r[:date_debut]}', '#{now}', '#{now}')" }.join(",\n  ")
        execute <<~SQL
          INSERT INTO phases (nom, annee, date_debut, created_at, updated_at)
          VALUES
            #{rows};
        SQL
      end
    end
  end
end
