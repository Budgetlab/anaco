class Echeancier < ApplicationRecord
  belongs_to :acte

  def self.ransackable_associations(auth_object = nil)
    ["acte"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["annee", "created_at", "acte_id", "id", "id_value", "montant_ae", "montant_cp", "updated_at"]
  end
end
