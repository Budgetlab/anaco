class ChangeMotifToArrayInSuspensions < ActiveRecord::Migration[8.1]
  def up
    # Renommer l'ancienne colonne pour la préserver pendant la migration
    rename_column :suspensions, :motif, :motif_old

    # Ajouter la nouvelle colonne tableau
    add_column :suspensions, :motif, :string, array: true, default: []

    # Migrer les données existantes : chaque motif string → tableau à un élément
    Suspension.reset_column_information
    Suspension.where.not(motif_old: nil).find_each do |s|
      s.update_column(:motif, [s.motif_old]) if s.motif_old.present?
    end

    # Supprimer l'ancienne colonne
    remove_column :suspensions, :motif_old
  end

  def down
    rename_column :suspensions, :motif, :motif_array

    add_column :suspensions, :motif, :string

    Suspension.reset_column_information
    Suspension.find_each do |s|
      s.update_column(:motif, s.motif_array&.first)
    end

    remove_column :suspensions, :motif_array
  end
end
