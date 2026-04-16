class AddStatutToBops < ActiveRecord::Migration[7.0]
  def up
    add_column :bops, :statut, :string, default: 'actif', null: false

    # Les bops avec dotation 'aucune' sont inactifs
    Bop.where(dotation: 'aucune').update_all(statut: 'inactif')
  end

  def down
    remove_column :bops, :statut
  end
end
