class Ht2Acte < ApplicationRecord
  belongs_to :user

  has_rich_text :commentaire_disponibilite_credits
  has_rich_text :commentaire_imputation_depense
  has_rich_text :commentaire_consommation_credits
  has_rich_text :commentaire_programmation
end
