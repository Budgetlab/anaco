class NormalizeCategorieT2HorsContratValue < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE actes SET categorie_t2 = 'hors contrat' WHERE categorie_t2 = 'hors_contrat'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE actes SET categorie_t2 = 'hors_contrat' WHERE categorie_t2 = 'hors contrat'
    SQL
  end
end
