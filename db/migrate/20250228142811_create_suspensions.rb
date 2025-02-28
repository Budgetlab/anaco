class CreateSuspensions < ActiveRecord::Migration[7.2]
  def change
    create_table :suspensions do |t|
      t.date :date_suspension
      t.string :motif
      t.text :observations
      t.date :date_reprise
      t.references :ht2_acte, null: false, foreign_key: true

      t.timestamps
    end
  end
end
