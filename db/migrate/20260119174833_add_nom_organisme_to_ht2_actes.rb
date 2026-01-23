class AddNomOrganismeToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :nom_organisme, :string
  end
end
