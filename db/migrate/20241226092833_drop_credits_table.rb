class DropCreditsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :credits
  end

  def down
    create_table :credits do |t|
      t.references :user, null: false, foreign_key: true
      t.references :programme, null: false, foreign_key: true
      t.string :phase
      t.integer :annee
      t.string :etat
      t.string :statut
      t.string :commentaire
      t.boolean :is_crg1
      t.date :date_document
      t.float :ae_i
      t.float :cp_i
      t.float :t2_i
      t.float :etpt_i
      t.timestamps
    end
  end
end
