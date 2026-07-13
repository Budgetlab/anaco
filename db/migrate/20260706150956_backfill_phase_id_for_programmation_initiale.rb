class BackfillPhaseIdForProgrammationInitiale < ActiveRecord::Migration[8.1]
  # Les avis dont la phase 'début de gestion' a été renommée 'programmation initiale'
  # (migration 20260627090000) n'ont jamais reçu de phase_id : le backfill initial
  # (20260619080537) matchait sur l'ancien nom. On les relie ici à la phase
  # (annee + 'programmation initiale') correspondante, la plus ancienne en cas de doublon.
  def up
    execute <<~SQL
      UPDATE avis
      SET phase_id = phases.id
      FROM phases
      WHERE phases.annee = avis.annee
        AND phases.nom   = 'programmation initiale'
        AND avis.phase   = 'programmation initiale'
        AND avis.phase_id IS NULL
        AND phases.id = (
          SELECT id FROM phases p2
          WHERE p2.annee = avis.annee AND p2.nom = 'programmation initiale'
          ORDER BY p2.date_debut ASC
          LIMIT 1
        );
    SQL
  end

  def down
    # Réversible : on repasse à NULL les avis 'programmation initiale' pointant vers
    # une phase de même nom. Sans risque puisque ces avis n'avaient pas de phase_id avant.
    execute <<~SQL
      UPDATE avis
      SET phase_id = NULL
      FROM phases
      WHERE avis.phase_id = phases.id
        AND phases.nom = 'programmation initiale'
        AND avis.phase = 'programmation initiale';
    SQL
  end
end
