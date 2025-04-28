class Ht2Acte < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :centre_financiers
  has_many :programmes, through: :centre_financiers
  has_many :suspensions, dependent: :destroy
  has_many :echeanciers, dependent: :destroy
  has_many :poste_lignes, dependent: :destroy
  accepts_nested_attributes_for :poste_lignes, reject_if: ->(attributes) { attributes['centre_financier_code'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :suspensions, reject_if: ->(attributes) { attributes['date_suspension'].blank? || attributes['motif'].blank?}, allow_destroy: true
  accepts_nested_attributes_for :echeanciers, reject_if: ->(attributes) { attributes['annee'].blank? || attributes['montant_ae'].blank? || attributes['montant_cp'].blank?}, allow_destroy: true
  before_save :set_etat_acte
  before_save :calculate_date_limite
  before_create :set_numero_utilisateur

  has_rich_text :commentaire_disponibilite_credits do |attachable|
    attachable.image_processing_options = {
      resize_to_limit: [nil, 400],
      format: :jpg
    }
  end

  scope :en_attente_validation, -> { where(etat: ["en attente de validation"]) }
  scope :en_cours_instruction, -> { where(etat: ["en cours d'instruction"]) }
  scope :en_pre_instruction, -> { where(etat: ["en pré-instruction"]) }
  scope :suspendus, -> { where(etat: ["suspendu"]) }

  def self.ransackable_attributes(auth_object = nil)
    ["action", "activite", "beneficiaire", "centre_financier_code", "commentaire_proposition_decision", "complexite", "consommation_credits", "created_at", "date_chorus", "date_cloture","date_limite", "decision_finale","delai_traitement", "disponibilite_credits", "etat", "id", "id_value", "imputation_depense", "instructeur", "montant_ae", "montant_global", "nature", "numero_chorus", "numero_tf", "numero_utilisateur","objet", "observations", "ordonnateur", "pre_instruction", "precisions_acte", "programmation", "proposition_decision", "sous_action", "type_acte", "type_observations", "updated_at", "user_id", "valideur"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["centre_financiers", "echeanciers","poste_lignes", "rich_text_commentaire_disponibilite_credits", "suspensions", "user"]
  end

  # Methode pour compter les actes en cours dont la date limite est dans les 5 jours à venir
  def self.echeance_courte
    where(etat: ["en cours d'instruction", 'en attente de validation', 'en attente de validation Chorus'])
      .where.not(date_limite: nil)
      .where("date_limite >= ?", Date.today)
      .where("date_limite <= ?", Date.today + 5.days)
      .count
  end

  # Méthode pour compter les actes en cours hors délai
  def self.count_current_with_long_delay
    where(etat: ["en cours d'instruction", 'en attente de validation', 'en attente de validation Chorus'])
      .where.not(date_limite: nil)
      .where("date_limite < ?", Date.today)
      .count
  end

  # Methode pour regrouper tous les actes avec le même numéro chorus
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

  def last_date_suspension
    # Trie les suspensions par date de création (descendant) et prend la première
    last_suspension = suspensions.order(created_at: :desc).first
    # Retourne la date de suspension si une suspension existe, sinon nil
    last_suspension&.date_suspension
  end

  def last_suspension
    suspensions.order(created_at: :desc).first
  end

  # Méthode de classe pour retrouver tous les actes ayant au moins une suspension
  def self.with_suspensions
    joins(:suspensions).distinct
  end

  # Méthode pour compter le nombre d'actes ayant au moins une suspension
  def self.count_with_suspensions
    with_suspensions.count
  end

  # Méthode pour calculer la durée moyenne des suspensions pour les actes clôturés
  def self.duree_moyenne_suspensions
    # Récupérer les IDs des suspensions associées à ces actes
    suspensions_ids = Suspension.where(ht2_acte_id: pluck(:id)).pluck(:id)

    # Si aucune suspension, retourner 0
    return 0 if suspensions_ids.empty?

    # Calculer la somme des durées de suspension
    somme_durees = 0
    count_suspensions = 0

    Suspension.where(id: suspensions_ids).each do |suspension|
      # Vérifier que les dates sont présentes avant de calculer
      if suspension.date_reprise.present? && suspension.date_suspension.present?
        duree = (suspension.date_reprise.to_date - suspension.date_suspension.to_date).to_i
        if duree > 0
          somme_durees += duree
          count_suspensions += 1
        end
      end
    end

    # Retourner la moyenne arrondie à l'entier le plus proche
    count_suspensions > 0 ? (somme_durees.to_f / count_suspensions).round : 0
  end

  # Méthode pour compter les actes clôturés avec délai > 15 jours
  def self.count_with_long_delay(seuil = 15)
    count { |acte| acte.delai_traitement.to_i > seuil }
  end

  def duree_total
    (date_cloture - date_chorus).to_i
  end

  def self.duree_total_moyenne
    # Si aucun acte, retourne 0
    return 0 if count.zero?
    # Somme des délais de traitement
    somme_durees = sum do |acte|
      acte.duree_total || 0
    end

    # Calcul de la moyenne
    (somme_durees / count.to_f).round
  end

  # Calcule le délai moyen de traitement des actes clôturés
  def self.delai_moyen_traitement
    # Si aucun acte, retourne 0
    return 0 if count.zero?

    # Somme des délais de traitement
    somme_delais = sum do |acte|
      acte.delai_traitement || 0
    end

    # Calcul de la moyenne
    (somme_delais / count.to_f).round
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

  # Méthode pour obtenir le numéro d'ordre de l'acte pour l'utilisateur
  def set_numero_utilisateur
    # Trouver le plus grand numéro actuellement utilisé pour cet utilisateur
    derniere_valeur = user.ht2_actes.maximum(:numero_utilisateur) || 0
    # Incrémenter pour le nouvel acte
    self.numero_utilisateur = derniere_valeur + 1
  end

  # Methode pour mettre à jour la date limite
  def calculate_date_limite
    self.date_limite = calculate_date_limite_value
  end
  def calculate_date_limite_value
    if suspensions.exists? && date_chorus.present?
      total_suspension_days = suspensions.sum do |suspension|
        if suspension.date_reprise.present?
          (suspension.date_reprise - suspension.date_suspension).to_i
        else
          0
        end
      end
      if type_acte == 'avis'
        date_chorus + 15.days + total_suspension_days
      elsif type_acte == 'visa' || type_acte == 'TF'
        if last_suspension&.date_reprise.present?
          last_suspension.date_reprise + 15.days
        else
          date_chorus + 15.days
        end
      end
    elsif date_chorus.present?
      date_chorus + 15.days
    end
  end
end
