class RemoveNumeroNomProgrammeFromBops < ActiveRecord::Migration[7.0]
  def change
    remove_column :bops, :numero_programme, :integer
    remove_column :bops, :nom_programme, :string
  end
end
