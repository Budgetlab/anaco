class CreateBops < ActiveRecord::Migration[7.0]
  def change
    create_table :bops do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :consultant
      t.string :ministere
      t.integer :numero_programme
      t.string :nom_programme
      t.string :code

      t.timestamps
    end
  end
end
