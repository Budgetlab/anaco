class CreateGestionSchemas < ActiveRecord::Migration[7.1]
  def change
    create_table :schemas do |t|
      t.references :programme, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :statut
      t.integer :annee

      t.timestamps
    end
    create_table :gestion_schemas do |t|
      t.references :programme, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :schema, null: false, foreign_key: true
      t.string :statut
      t.string :vision
      t.string :profil
      t.integer :annee
      t.float :prevision_solde_budgetaire_ae
      t.float :prevision_solde_budgetaire_cp
      t.float :mer_ae
      t.float :mer_cp
      t.float :mobilisation_mer_ae
      t.float :mobilisation_mer_cp
      t.float :fongibilite_ae
      t.float :fongibilite_cp
      t.float :decret_ae
      t.float :decret_cp
      t.float :credits_ouverts_ae
      t.float :credits_ouverts_cp
      t.float :charges_a_payer_ae
      t.float :charges_a_payer_cp
      t.float :credits_reports_ae
      t.float :credits_reports_cp
      t.float :reports_autre_ae
      t.float :reports_autre_cp
      t.text :commentaire

      t.timestamps
    end
  end
end
