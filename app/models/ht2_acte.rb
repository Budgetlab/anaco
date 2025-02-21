class Ht2Acte < ApplicationRecord
  belongs_to :user

  has_rich_text :commentaire_disponibilite_credits do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end
  has_rich_text :commentaire_imputation_depense
  has_rich_text :commentaire_consommation_credits
  has_rich_text :commentaire_programmation
end
