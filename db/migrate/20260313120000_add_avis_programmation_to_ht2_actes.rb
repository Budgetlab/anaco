class AddAvisProgrammationToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :avis_programmation, :boolean, default: true
  end
end
