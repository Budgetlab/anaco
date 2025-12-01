class AddNumeroTfToPosteLignes < ActiveRecord::Migration[7.2]
  def change
    add_column :poste_lignes, :numero_tf, :string
  end
end
