class CreateTransferts < ActiveRecord::Migration[7.1]
  def change
    create_table :transferts do |t|
      t.references :gestion_schema, null: false, foreign_key: true
      t.string :nature
      t.float :montant_ae
      t.float :montant_cp
      t.references :programme, null: false, foreign_key: true

      t.timestamps
    end
  end
end
