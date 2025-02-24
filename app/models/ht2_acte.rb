class Ht2Acte < ApplicationRecord
  belongs_to :user
  before_save :set_etat_acte

  has_rich_text :commentaire_disponibilite_credits do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end
  has_rich_text :commentaire_imputation_depense
  has_rich_text :commentaire_consommation_credits
  has_rich_text :commentaire_programmation

  private

  def set_etat_acte
    if date_chorus.nil? || (numero_chorus.nil? && nature != "Liste d'actes")
      etat = "En pré-instruction"
      pre_instruction = true
    elsif etat.nil?
      etat = "En instruction"
    end
  end
end
