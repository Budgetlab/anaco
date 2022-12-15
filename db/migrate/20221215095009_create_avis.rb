class CreateAvis < ActiveRecord::Migration[7.0]
  def change
    create_table :avis do |t|
      t.string :phase
      t.date :date_reception
      t.date :date_envoi
      t.boolean :is_delai
      t.boolean :is_crg1
      t.float :ae_i
      t.float :cp_i
      t.float :t2_i
      t.float :etpt_i
      t.float :ae_f
      t.float :cp_f
      t.float :t2_f
      t.float :etpt_f
      t.string :statut
      t.string :etat
      t.string :commentaire
      t.references :bop, null: false, foreign_key: true

      t.timestamps
    end
  end
end
