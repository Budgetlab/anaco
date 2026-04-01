class CreateOrganismes < ActiveRecord::Migration[8.1]
  def change
    create_table :organismes do |t|
      t.string :nom, null: false
      t.string :acronyme
      t.string :statut
      t.references :user, null: false, foreign_key: true
      t.integer :id_opera

      t.timestamps
    end

    add_index :organismes, :id_opera
    add_index :organismes, :nom
  end
end
