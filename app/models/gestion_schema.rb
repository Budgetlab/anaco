class GestionSchema < ApplicationRecord
  belongs_to :programme
  belongs_to :user
  belongs_to :schema

  def solde_total_ae
    prevision_solde_budgetaire_ae + (mobilisation_mer_ae || 0)
  end
  def solde_total_cp
    prevision_solde_budgetaire_cp + (mobilisation_mer_cp || 0)
  end
  def self.ransackable_attributes(auth_object = nil)
    ["annee", "charges_a_payer_ae", "charges_a_payer_cp", "commentaire", "created_at", "credits_ouverts_ae", "credits_ouverts_cp", "credits_reports_ae", "credits_reports_cp", "decret_ae", "decret_cp", "fongibilite_ae", "fongibilite_cp", "id", "id_value", "mer_ae", "mer_cp", "mobilisation_mer_ae", "mobilisation_mer_cp", "prevision_solde_budgetaire_ae", "prevision_solde_budgetaire_cp", "profil", "programme_id", "reports_autre_ae", "reports_autre_cp", "schema_id", "statut", "updated_at", "user_id", "vision"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["programme", "schema", "user"]
  end
end
