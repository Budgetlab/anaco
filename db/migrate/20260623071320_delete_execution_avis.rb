class DeleteExecutionAvis < ActiveRecord::Migration[8.1]
  # Suppression définitive des avis avec phase='execution'.
  # Cette phase a existé historiquement (2023) et n'est plus utilisée.
  # Tous les callsites `where.not(phase: 'execution')` sont retirés en parallèle.
  def up
    count = Avi.where(phase: 'execution').count
    say "Suppression de #{count} avis avec phase='execution'."
    Avi.where(phase: 'execution').delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "Suppression définitive des avis 'execution'. Restaurer depuis backup BDD si nécessaire."
  end
end
