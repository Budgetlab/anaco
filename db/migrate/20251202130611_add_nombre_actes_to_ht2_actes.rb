class AddNombreActesToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :nombre_actes, :integer
  end
end
