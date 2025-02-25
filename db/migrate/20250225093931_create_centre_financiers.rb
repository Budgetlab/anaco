class CreateCentreFinanciers < ActiveRecord::Migration[7.2]
  def change
    create_table :centre_financiers do |t|
      t.references :bop, null: false, foreign_key: true
      t.string :code

      t.timestamps
    end
  end
end
