class CreateMissions < ActiveRecord::Migration[7.1]
  def change
    create_table :missions do |t|
      t.string :nom
      t.references :ministere, null: false, foreign_key: true

      t.timestamps
    end
  end
end
