class AddFluxToPosteLignes < ActiveRecord::Migration[7.2]
  def change
    add_column :poste_lignes, :flux, :string
  end
end
