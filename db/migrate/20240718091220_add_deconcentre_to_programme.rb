class AddDeconcentreToProgramme < ActiveRecord::Migration[7.1]
  def change
    add_column :programmes, :deconcentre, :boolean
    add_column :programmes, :dotation, :string
    add_column :programmes, :statut, :string, default: 'Actif'
  end
end
