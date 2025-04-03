class CreatePosteLignes < ActiveRecord::Migration[7.2]
  def change
    create_table :poste_lignes do |t|
      t.references :ht2_acte, null: false, foreign_key: true
      t.string :centre_financier_code
      t.float :montant
      t.string :domaine_fonctionnel
      t.string :fonds
      t.string :compte_budgetaire
      t.string :code_activite
      t.string :axe_ministeriel

      t.timestamps
    end
  end
end
