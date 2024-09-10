class AddConsultantIdToBops < ActiveRecord::Migration[7.1]
  def up
    # Ajoute la colonne programme_id et dcb_id avec une contrainte foreign_key
    add_reference :bops, :programme, foreign_key: true
    add_reference :bops, :dcb, foreign_key: { to_table: :users }

    # Parcourir chaque `bop` et mettre à jour la colonne `consultant_id`
    # avec la valeur actuelle de la colonne `consultant`
    Bop.find_each do |bop|
      programme = Programme.find_by(numero: bop.numero_programme)
      bop.update!(dcb_id: bop.consultant, programme_id: programme.id)
    end
    # Supprime ensuite la colonne `consultant` de la table `bops`
    remove_column :bops, :consultant
  end

  def down
    add_column :bops, :consultant, :integer

    # Parcourir chaque `bop` et mettre à jour la colonne `consultant`
    # avec la valeur actuelle de la colonne `consultant_id`
    Bop.find_each do |bop|
      bop.update!(consultant: bop.dcb_id)
    end
    remove_reference :bops, :dcb
    remove_reference :bops, :programme
  end
end
