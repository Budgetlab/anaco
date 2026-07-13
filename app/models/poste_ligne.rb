class PosteLigne < ApplicationRecord
  belongs_to :acte

  def self.ransackable_associations(auth_object = nil)
    ["acte"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["axe_ministeriel", "centre_financier_code", "code_activite", "compte_budgetaire", "created_at", "domaine_fonctionnel", "flux", "fonds", "groupe_marchandises", "acte_id", "id", "id_value", "montant", "numero", "numero_tf", "updated_at"]
  end
end
