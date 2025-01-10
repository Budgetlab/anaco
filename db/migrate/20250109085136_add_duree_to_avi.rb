class AddDureeToAvi < ActiveRecord::Migration[7.2]
  def change
    add_column :avis, :duree_prevision, :integer, default: 12
  end
end
