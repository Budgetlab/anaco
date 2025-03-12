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

  def duplicate_with_rich_text
    # Dupliquer l'acte de base
    new_acte = self.dup

    # Dupliquer les champs rich_text
    %w[commentaire_disponibilite_credits commentaire_imputation_depense commentaire_consommation_credits commentaire_programmation].each do |rich_text_field|
      rich_text = self.send("rich_text_#{rich_text_field}")
      if rich_text.present?
        new_acte.send("#{rich_text_field}=", rich_text.body.to_s)
      end
    end

    return new_acte
  end

  def self.ransackable_attributes(auth_object = nil)
    ["action", "activite", "beneficiaire", "centre_financier_code", "commentaire_proposition_decision", "complexite", "consommation_credits", "created_at", "date_chorus", "decision_finale", "disponibilite_credits", "etat", "id", "id_value", "imputation_depense", "instructeur", "lien_tf", "montant_ae", "montant_global", "nature", "numero_chorus", "numero_tf", "objet", "observations", "ordonnateur", "pre_instruction", "precisions_acte", "programmation", "proposition_decision", "sous_action", "type_acte", "type_observations", "updated_at", "user_id", "valideur"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["centre_financiers", "rich_text_commentaire_consommation_credits", "rich_text_commentaire_disponibilite_credits", "rich_text_commentaire_imputation_depense", "rich_text_commentaire_programmation", "suspensions", "user"]
  end

  def last_date_suspension
    # Trie les suspensions par date de création (descendant) et prend la première
    last_suspension = suspensions.order(created_at: :desc).first
    # Retourne la date de suspension si une suspension existe, sinon nil
    last_suspension&.date_suspension
  end

  def last_suspension
    suspensions.order(created_at: :desc).first
  end

  def date_limite
    if suspensions.exists?
      total_suspension_days = suspensions.sum do |suspension|
        if suspension.date_reprise.present?
          (suspension.date_reprise - suspension.date_suspension).to_i
        else
          0
        end
      end
      if type_acte == 'avis'
        date_chorus + 15.days + total_suspension_days
      elsif type_acte == 'visa'
        if last_suspension&.date_reprise.present?
          last_suspension.date_reprise + 15.days
        else
          date_chorus + 15.days
        end
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
    if !date_chorus.present? || (!numero_chorus.present? && nature != "Liste d'actes")
      self.etat = "en pré-instruction"
      self.pre_instruction = true
    elsif self.suspensions.present? && self.suspensions.last.date_reprise.nil?
      self.etat = "suspendu"
    elsif !etat.present? || (etat != 'clôturé' && etat != 'en attente validation')
      self.etat = "en cours d'instruction"
    end
  end
end
