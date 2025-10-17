class CreateEcheanciers < ActiveRecord::Migration[7.2]
  def change
    create_table :echeanciers do |t|
      t.references :ht2_acte, null: false, foreign_key: true
      t.integer :annee
      t.float :montant_ae
      t.float :montant_cp

      t.timestamps
    end
  end
end
