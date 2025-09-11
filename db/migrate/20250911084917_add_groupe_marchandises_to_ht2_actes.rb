class AddGroupeMarchandisesToHt2Actes < ActiveRecord::Migration[7.2]
  def change
    add_column :ht2_actes, :groupe_marchandises, :string
    add_column :poste_lignes, :groupe_marchandises, :string
  end
end
