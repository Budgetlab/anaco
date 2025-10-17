class AddNumeroToPosteLigne < ActiveRecord::Migration[7.2]
  def change
    add_column :poste_lignes, :numero, :string
  end
end
