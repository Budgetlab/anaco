class Echeancier < ApplicationRecord
  belongs_to :ht2_acte

  def self.ransackable_associations(auth_object = nil)
    ["ht2_acte"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["annee", "created_at", "ht2_acte_id", "id", "id_value", "montant_ae", "montant_cp", "updated_at"]
  end
end
