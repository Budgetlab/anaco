class AddPhaseIdToAvis < ActiveRecord::Migration[8.1]
  def change
    # Nullable pour rétro-compat : tous les avis existants ont phase_id NULL avant backfill.
    # Le champ phase (string) est conservé en parallèle pour les filtres existants.
    add_reference :avis, :phase, null: true, foreign_key: true, index: true

    reversible do |dir|
      dir.up do
        # Backfill : associe chaque avis existant à la phase (annee + nom) correspondante.
        # Quand plusieurs phases portent le même nom dans la même année (futur cas SV1/SV2),
        # on prend la plus ancienne par défaut. Les avis de phase 'execution' (sans entrée
        # dans la table phases) restent à NULL — cohérent avec la sémantique.
        execute <<~SQL
          UPDATE avis
          SET phase_id = phases.id
          FROM phases
          WHERE phases.annee = avis.annee
            AND phases.nom   = avis.phase
            AND avis.phase_id IS NULL
            AND phases.id = (
              SELECT id FROM phases p2
              WHERE p2.annee = avis.annee AND p2.nom = avis.phase
              ORDER BY p2.date_debut ASC
              LIMIT 1
            );
        SQL
      end
    end
  end
end
