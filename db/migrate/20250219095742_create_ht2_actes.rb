class CreateHt2Actes < ActiveRecord::Migration[7.2]
  def change
    create_table :ht2_actes do |t|
      t.string :type_acte, null: false
      t.string :etat
      t.string :instructeur
      t.string :nature
      t.float :montant_ae
      t.float :montant_global
      t.string :centre_financier_code
      t.date :date_chorus
      t.string :numero_chorus
      t.string :beneficiaire
      t.string :objet
      t.string :ordonnateur
      t.text :precisions_acte
      t.boolean :pre_instruction
      t.string :action
      t.string :sous_action
      t.string :activite
      t.boolean :lien_tf
      t.string :numero_tf
      t.boolean :disponibilite_credits
      t.boolean :imputation_depense
      t.boolean :consommation_credits
      t.boolean :programmation
      t.string :proposition_decision
      t.text :commentaire_proposition_decision
      t.string :complexite
      t.text :observations
      t.string :type_observations, array: true, default: []
      t.references :user, null: false, foreign_key: true
      t.string :valideur
      t.string :decision_finale

      t.timestamps
    end
  end
end
