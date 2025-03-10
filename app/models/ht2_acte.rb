class Ht2Acte < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :centre_financiers
  has_many :suspensions
  accepts_nested_attributes_for :suspensions, reject_if: :all_blank, allow_destroy: true
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
  def self.ransackable_attributes(auth_object = nil)
    ["action", "activite", "beneficiaire", "commentaire_proposition_decision", "complexite", "consommation_credits", "created_at", "date_chorus", "disponibilite_credits", "etat", "id", "imputation_depense", "instructeur", "lien_tf", "montant_ae", "montant_global", "nature", "numero_chorus", "numero_tf", "objet", "observations", "ordonnateur", "pre_instruction", "precisions_acte", "programmation", "proposition_decision", "sous_action", "type_acte", "type_observations", "updated_at", "user_id"]
  end

  def last_date_suspension
    # Trie les suspensions par date de création (descendant) et prend la première
    last_suspension = suspensions.order(created_at: :desc).first
    # Retourne la date de suspension si une suspension existe, sinon nil
    last_suspension&.date_suspension
  end

  def last_suspension
    last_suspension = suspensions.order(created_at: :desc).first
  end

  def date_limite
    if suspensions.exists?
      if type == 'avis'
        date_chorus + 15.days + last_suspension&.date_reprise - last_date_suspension
      elsif type == 'visa'
        last_date_suspension + 15.days
      end
    else
      date_chorus + 15.days
    end
  end

  def tous_actes_meme_chorus
    return [self] if numero_chorus.blank?
    Ht2Acte.where(numero_chorus: numero_chorus)
           .order(created_at: :asc)
  end

  private

  def set_etat_acte
    if date_chorus.nil? || (numero_chorus.nil? && nature != "Liste d'actes")
      self.etat = "pre-instruction"
      self.pre_instruction = true
    elsif self.suspensions.present? && self.suspensions.last.date_reprise.nil?
      self.etat = "suspendu"
    elsif self.etat.nil?
      self.etat = "instruction"
    end
  end
end
