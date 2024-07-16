class AddConsultantIdToBops < ActiveRecord::Migration[7.1]
  def up
    # Ajoute la colonne consultant_id avec une contrainte foreign_key
    add_reference :bops, :consultant, foreign_key: { to_table: :users }

    # Parcourir chaque `bop` et mettre à jour la colonne `consultant_id`
    # avec la valeur actuelle de la colonne `consultant`
    Bop.find_each { |bop| bop.update!(consultant_id: bop.consultant) }
    # Supprime ensuite la colonne `consultant` de la table `bops`
    remove_column :bops, :consultant
  end

  def down
    add_column :bops, :consultant, :integer

    # Parcourir chaque `bop` et mettre à jour la colonne `consultant`
    # avec la valeur actuelle de la colonne `consultant_id`
    Bop.find_each { |bop| bop.update!(consultant: bop.consultant_id) }
    remove_reference :bops, :consultant
  end
end
