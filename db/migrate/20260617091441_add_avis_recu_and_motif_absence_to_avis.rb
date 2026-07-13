class AddAvisRecuAndMotifAbsenceToAvis < ActiveRecord::Migration[8.1]
  def change
    add_column :avis, :avis_recu, :boolean, default: true, null: false
    add_column :avis, :motif_absence, :string
  end
end
