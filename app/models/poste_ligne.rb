class PosteLigne < ApplicationRecord
  belongs_to :ht2_acte

  def self.ransackable_associations(auth_object = nil)
    ["ht2_acte"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["axe_ministeriel", "centre_financier_code", "code_activite", "compte_budgetaire", "created_at", "domaine_fonctionnel", "fonds","flux", "ht2_acte_id", "id", "id_value", "montant", "numero","updated_at"]
  end
end
