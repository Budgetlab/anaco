class AddSoutenabiliteAndConformiteToHt2Actes < ActiveRecord::Migration[8.1]
  def change
    add_column :ht2_actes, :soutenabilite, :boolean, default: true
    add_column :ht2_actes, :conformite, :boolean, default: true
  end
end
