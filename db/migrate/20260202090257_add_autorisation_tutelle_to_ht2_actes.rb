class AddAutorisationTutelleToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :autorisation_tutelle, :boolean
  end
end
