class RenameDebutDeGestionToProgrammationInitiale < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE phases SET nom = 'programmation initiale' WHERE nom = 'début de gestion';
      UPDATE avis   SET phase = 'programmation initiale' WHERE phase = 'début de gestion';
    SQL
  end

  def down
    execute <<~SQL
      UPDATE avis   SET phase = 'début de gestion' WHERE phase = 'programmation initiale';
      UPDATE phases SET nom = 'début de gestion' WHERE nom = 'programmation initiale';
    SQL
  end
end
