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
  has_rich_text :commentaire_imputation_depense do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end
  has_rich_text :commentaire_consommation_credits do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end
  has_rich_text :commentaire_programmation do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end

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
    ["action", "activite", "beneficiaire", "centre_financier_code", "commentaire_proposition_decision", "complexite", "consommation_credits", "created_at", "date_chorus", "date_cloture", "decision_finale", "disponibilite_credits", "etat", "id", "id_value", "imputation_depense", "instructeur", "lien_tf", "montant_ae", "montant_global", "nature", "numero_chorus", "numero_tf", "objet", "observations", "ordonnateur", "pre_instruction", "precisions_acte", "programmation", "proposition_decision", "sous_action", "type_acte", "type_observations", "updated_at", "user_id", "valideur"]
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
    Ht2Acte.where(numero_chorus: numero_chorus, user_id: user_id)
  end

  def dernier_acte_cloture_chorus
    # Récupère le dernier acte clôturé
    tous_actes_meme_chorus.where(etat: 'clôturé').order(created_at: :desc).first
  end

  def numero_saisine
    actes = tous_actes_meme_chorus.sort_by(&:id) # Tri par ID (ordre croissant)
    actes.index(self)&.+(1) # Ajoute 1 à l'index pour obtenir le numéro de saisine
  end

  # Méthode pour obtenir le numéro d'ordre de l'acte pour l'utilisateur
  def numero_utilisateur
    # Récupère tous les actes de l'utilisateur triés par ID
    actes_utilisateur = user.ht2_actes.order(:id)

    # Trouve l'index de l'acte actuel et ajoute 1 pour avoir un numéro commençant par 1
    actes_utilisateur.index(self) + 1
  end

  # Méthode de classe pour retrouver tous les actes ayant au moins une suspension
  def self.with_suspensions
    joins(:suspensions)
      .where(etat: ['clôturé', 'en attente de validation'])
      .distinct
  end

  # Méthode pour compter le nombre d'actes ayant au moins une suspension
  def self.count_with_suspensions
    with_suspensions.count
  end

  # Méthode pour calculer la durée moyenne des suspensions pour les actes clôturés
  def self.duree_moyenne_suspensions
    # Récupérer tous les actes clôturés
    actes_clotures = where(etat: ['clôturé','en attente de validation'])

    # Récupérer toutes les suspensions associées à ces actes
    suspensions_ids = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).pluck(:id)

    # Si aucune suspension valide, retourner 0
    return 0 if suspensions_ids.empty?

    # Calculer la somme des durées de suspension
    somme_durees = 0
    count_suspensions = 0

    Suspension.where(id: suspensions_ids).each do |suspension|
      duree = (suspension.date_reprise.to_date - suspension.date_suspension.to_date).to_i
      if duree > 0
        somme_durees += duree
        count_suspensions += 1
      end
    end

    # Retourner la moyenne arrondie à l'entier le plus proche
    count_suspensions > 0 ? (somme_durees.to_f / count_suspensions).round : 0
  end

  # Calcule le délai de traitement pour un acte spécifique
  def delai_traitement
    # Vérifier que l'acte est clôturé et a les dates nécessaires
    return 0 unless etat == 'clôturé' && date_chorus.present? && date_cloture.present?

    delai_total = (date_cloture.to_date - date_chorus.to_date).to_i

    # Si pas de suspension, retourne simplement le délai total
    return delai_total if suspensions.empty?

    # Traitement différent selon le type d'acte
    if type_acte == 'avis'
      # Pour les avis, soustraire la durée de chaque suspension
      duree_suspensions = suspensions.sum do |suspension|
        if suspension.date_suspension.present? && suspension.date_reprise.present?
          (suspension.date_reprise.to_date - suspension.date_suspension.to_date).to_i
        else
          0
        end
      end

      # Délai total moins durée des suspensions
      [delai_total - duree_suspensions, 0].max
    elsif type_acte == 'visa'
      # Pour les visas, prendre le délai entre la dernière reprise et la clôture
      derniere_suspension = suspensions.order(date_reprise: :desc).first

      if derniere_suspension&.date_reprise.present?
        (date_cloture.to_date - derniere_suspension.date_reprise.to_date).to_i
      else
        delai_total
      end
    else
      # Si type inconnu, retourner le délai total
      delai_total
    end
  end

  # Méthode pour compter les actes clôturés avec délai > 15 jours
  def self.count_with_long_delay(seuil = 15)
    # Récupérer tous les actes clôturés ayant les dates nécessaires
    actes_clotures = where(etat: 'clôturé')

    # Compter les actes dont le délai de traitement dépasse le seuil
    actes_clotures.count { |acte| acte.delai_traitement > seuil }
  end

  # Calcule le délai moyen de traitement des actes clôturés
  def self.delai_moyen_traitement
    actes_clotures = where(etat: 'clôturé')

    # Si aucun acte clôturé, retourne 0
    return 0 if actes_clotures.empty?

    # Somme des délais de traitement
    somme_delais = actes_clotures.sum do |acte|
      acte.delai_traitement
    end

    # Calcul de la moyenne
    (somme_delais / actes_clotures.count.to_f).round
  end

  private

  def set_etat_acte
    if !date_chorus.present? || (!numero_chorus.present? && nature != "Liste d'actes")
      self.etat = "en pré-instruction"
      self.pre_instruction = true
    elsif self.suspensions.present? && self.suspensions.last.date_reprise.nil?
      self.etat = "suspendu"
    elsif !etat.present? || etat == "en pré-instruction"
      self.etat = "en cours d'instruction"
    end
  end
end
