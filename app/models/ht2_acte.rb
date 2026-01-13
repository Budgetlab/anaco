class Ht2Acte < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :centre_financiers
  # Association via le champ centre_financier_code principal
  belongs_to :centre_financier_principal,
             class_name: 'CentreFinancier',
             foreign_key: :centre_financier_code,
             primary_key: :code,
             optional: true
  # Programme principal (via le centre_financier_code)
  delegate :programme, to: :centre_financier_principal, prefix: true, allow_nil: true
  # Cela créera automatiquement la méthode centre_financier_principal_programme
  # Mais vous pouvez créer un alias :
  alias_method :programme_principal, :centre_financier_principal_programme

  has_many :suspensions, dependent: :destroy
  has_many :echeanciers, dependent: :destroy
  has_many :poste_lignes, dependent: :destroy
  accepts_nested_attributes_for :poste_lignes, reject_if: ->(attributes) { attributes['centre_financier_code'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :suspensions, reject_if: ->(attributes) { attributes['date_suspension'].blank? || attributes['motif'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :echeanciers, reject_if: ->(attributes) { attributes['annee'].blank? || attributes['montant_ae'].blank? || attributes['montant_cp'].blank? }, allow_destroy: true
  before_save :upcase_centre_financier_code
  after_save :set_etat_acte
  after_save :set_numero_utilisateur, if: :saved_change_to_annee?
  after_save :calculate_date_limite_if_needed
  after_save :associate_centre_financier_if_needed
  after_save :calculate_delai_traitement_if_needed
  after_save :purge_pdf_files_on_update

  has_rich_text :commentaire_disponibilite_credits

  scope :en_attente_validation, -> { where(etat: ["à valider", "à suspendre"]) }
  scope :en_cours_instruction, -> { where(etat: ["en cours d'instruction"]) }
  scope :en_pre_instruction, -> { where(etat: ["en pré-instruction"]) }
  scope :suspendus, -> { where(etat: ["suspendu"]) }
  scope :a_cloturer, -> { where(etat: ["à clôturer"]) }
  scope :clotures, -> { where(etat: ['clôturé', 'clôturé après pré-instruction']) }
  scope :clotures_seuls, -> { where(etat: 'clôturé') }
  scope :non_clotures, -> { where.not(etat: ['clôturé', 'clôturé après pré-instruction']) }
  scope :annee_courante, -> { where(annee: Date.current.year) }
  # Ceux qui ne sont pas clos (année N , N-1 ..) + ceux qui sont clos sur l'annee N
  scope :actifs_annee_courante, -> {
    where(
      "(date_cloture IS NULL) OR (date_cloture IS NOT NULL AND annee = ?)",
      Date.current.year
    )
  }

  has_many_attached :pdf_files
  def pdf_attached?
    pdf_files.attached? && pdf_files.any?
  end

  def pdf_filename
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    "acte_#{numero_formate}_#{timestamp}.pdf"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["action", "activite", "annee", "beneficiaire", "categorie", "centre_financier_code", "commentaire_proposition_decision", "consommation_credits", "created_at", "date_chorus", "date_cloture", "date_limite", "decision_finale", "delai_traitement", "disponibilite_credits", "etat", "groupe_marchandises", "id", "id_value", "imputation_depense", "instructeur", "liste_actes", "montant_ae", "montant_global", "nature", "nombre_actes", "numero_chorus", "numero_formate", "numero_marche", "numero_tf", "numero_utilisateur", "objet", "observations", "ordonnateur", "pdf_generation_status", "pre_instruction", "precisions_acte", "programmation", "programmation_prevue", "proposition_decision", "renvoie_instruction", "services_votes", "sheet_data", "sous_action", "type_acte", "type_engagement", "type_observations", "updated_at", "user_id", "valideur"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["centre_financier_principal", "centre_financiers", "echeanciers", "poste_lignes", "rich_text_commentaire_disponibilite_credits", "suspensions", "user"]
  end

  # Custom ransacker pour filtrer par présence de suspensions
  #ransacker :has_suspensions do
  #Arel.sql("EXISTS(SELECT 1 FROM suspensions WHERE suspensions.ht2_acte_id = ht2_actes.id)")
    #end

  # États valides pour les transitions
  VALID_ETATS = [
    "en pré-instruction",
    "en cours d'instruction",
    "suspendu",
    "à suspendre",
    "à valider",
    "à clôturer",
    "clôturé après pré-instruction",
    "clôturé"
  ].freeze
  # Methode pour compter les actes en cours dont la date limite est dans les 5 jours à venir
  def self.echeance_courte
    where(etat: ["en cours d'instruction", 'à valider', 'à clôturer'])
      .where.not(date_limite: nil)
      .where("date_limite >= ?", Date.today)
      .where("date_limite <= ?", Date.today + 5.days)
      .count
  end

  # Méthode pour compter les actes en cours hors délai
  def self.count_current_with_long_delay
    where(etat: ["en cours d'instruction", 'à valider', 'à clôturer'])
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
    return nil if tous_actes_meme_chorus.is_a?(Array)

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

  # Rend le recalcul appelable publiquement
  def recalculate_delai_traitement!
    calculate_delai_traitement
  end

  # Une suspension est "ouverte" si date_reprise est nulle OU si un des champs obligatoires manque
  def suspension_ouverte
    suspensions.find { |s| s.date_reprise.nil? }
  end

  def suspension_ouverte?
    suspension_ouverte.present?
  end

  def self.import(file)
    data = Roo::Spreadsheet.open(file.path)
    # Ligne 1 = noms de colonnes
    headers = data.row(1).map(&:to_s).map(&:strip)
    data.each_with_index do |row, idx|
      next if idx == 0 || idx == 1 # skip header

      row_data = Hash[[headers, row].transpose]
      user = User.find_by(nom: row_data["user"].to_s.strip)
      next unless user && row_data["montant_ae"].present? && row_data["date_cloture"].present?

      # Champs
      acte = Ht2Acte.new(
        type_acte: row_data["type_acte"],
        annee: row_data["annee"],
        instructeur: row_data["instructeur"],
        ordonnateur: row_data["ordonnateur"],
        nature: row_data["nature"],
        montant_ae: row_data["montant_ae"].to_f,
        montant_global: ["Engagement initial", "Affectation initiale"].include?(row_data["type_engagement"]) ? row_data["montant_ae"].to_f : nil,
        centre_financier_code: row_data["centre_financier_code"],
        date_chorus: row_data["date_chorus"].is_a?(Date) ? row_data["date_chorus"] : nil,
        date_cloture: row_data["date_cloture"].is_a?(Date) ? row_data["date_cloture"] : nil,
        date_limite: row_data["date_limite"].is_a?(Date) ? row_data["date_limite"] : nil,
        numero_chorus: row_data["numero_chorus"].to_s,
        beneficiaire: row_data["beneficiaire"],
        objet: row_data["objet"],
        etat: row_data["decision_finale"].present? ? "clôturé" : "clôturé après pré-instruction",
        numero_tf: row_data["numero_tf"].to_s,
        numero_marche: row_data["numero_marche"].to_s,
        user: user,
        proposition_decision: row_data["proposition_decision"].present? ? row_data["proposition_decision"] : row_data["decision_finale"],
        decision_finale: row_data["decision_finale"],
        precisions_acte: row_data["precisions_acte"],
        valideur: row_data["valideur"].present? ? row_data["valideur"] : row_data["instructeur"],
        categorie: row_data["categorie"].to_s,
        pre_instruction: ["OUI", "Oui"].include?(row_data["pre_instruction"]) ? true : false,
        disponibilite_credits: ["NON", "Non"].include?(row_data["disponibilite_credits"]) ? false : true,
        imputation_depense: ["NON", "Non"].include?(row_data["imputation_depense"]) ? false : true,
        consommation_credits: ["NON", "Non"].include?(row_data["consommation_credits"]) ? false : true,
        programmation: ["NON", "Non"].include?(row_data["programmation"]) ? false : true,
        type_engagement: row_data["type_engagement"],
        programmation_prevue: ["NON", "Non"].include?(row_data["programmation_prevue"]) ? false : true,
        observations: row_data["observations"],
        commentaire_proposition_decision: row_data["commentaire_proposition_decision"],
        nombre_actes: row_data["nombre_actes"].to_i,
        liste_actes: row_data["nombre_actes"].to_i > 1 ? true : false,
        type_observations: row_data["type_observations"].present? ? [row_data["type_observations"]] : []
      )

      if acte.save
        if row_data["date_suspension"].present? && row_data["date_reprise"].present?
          acte.suspensions.create(
            date_suspension: row_data["date_suspension"],
            date_reprise: row_data["date_reprise"],
            motif: row_data["motif"] || 'Autre'
          )
          # recalcul APRÈS les suspensions
          acte.recalculate_delai_traitement!
        end
      else
        Rails.logger.warn "Erreur à la ligne #{i} : #{acte.errors.full_messages.join(', ')}"
      end
    end
  end


  private

  def set_etat_acte
    if self.suspensions.present? && self.suspensions.last&.date_reprise.nil? && !["suspendu", "à suspendre"].include?(self.etat)
      update_column(:etat,"suspendu")
    elsif !etat.present? || !VALID_ETATS.include?(etat)
      update_column(:etat, "en cours d'instruction")
    elsif self.etat == "en pré-instruction"
      update_column(:pre_instruction , true)
    elsif self.etat == 'suspendu' && self.suspensions.where(date_reprise: nil).empty?
      update_column(:etat, "en cours d'instruction")
    elsif self.etat == "clôturé" && self.decision_finale.nil?
      update_column(:decision_finale, self.proposition_decision)
    end
  end

  # Méthode pour obtenir le numéro d'ordre de l'acte pour l'utilisateur + annee
  def set_numero_utilisateur
    annee_courte = self.annee.to_s.last(2)
    # Trouver le plus grand numéro pour cette année et cet utilisateur
    pattern = "#{annee_courte}-%"
    derniere_valeur = user.ht2_actes
                          .where("numero_formate LIKE ?", pattern)
                          .maximum(:numero_utilisateur) || 0
    # Incrémenter pour le nouvel acte
    nouveau_numero = derniere_valeur + 1
    update_columns(
      numero_utilisateur: nouveau_numero,
      numero_formate: "#{annee_courte}-#{nouveau_numero.to_s.rjust(4, '0')}"
      )
  end

  # Methode pour mettre à jour la date limite
  def calculate_date_limite_if_needed
    return unless ['en cours d\'instruction', 'suspendu', 'à valider'].include?(etat) && date_chorus.present?

    new_date_limite = if etat == 'suspendu'
                        nil
                      else
                        calculate_date_limite_value
                      end

    if new_date_limite != date_limite
      update_column(:date_limite, new_date_limite)
    end
  end

  def calculate_date_limite_value
    return nil unless date_chorus.present?

    base_date = date_chorus + 15.days

    return base_date unless suspensions.exists?

    total_suspension_days = suspensions.sum do |suspension|
      if suspension.date_reprise.present? && suspension.date_suspension.present?
        (suspension.date_reprise - suspension.date_suspension).to_i
      else
        0
      end
    end
    case type_acte
    when 'avis'
      base_date + total_suspension_days
    when 'visa', 'TF'
      if last_suspension&.date_reprise.present?
        last_suspension.date_reprise + 15.days
      else
        base_date
      end
    else
      base_date
    end
  end

  def associate_centre_financier_if_needed
    # Vérifier si le centre_financier_code a changé
    if saved_change_to_centre_financier_code?
      associate_centre_financier
    end
  end

  def associate_centre_financier
    return unless centre_financier_code.present?

    centre = CentreFinancier.find_by(code: centre_financier_code)
    centre_financiers.destroy_all
    if centre
      # Supprimer les associations existantes et ajouter la nouvelle
      centre_financiers << centre
    else
      # Si pas de code ou code invalide, supprimer toutes les associations
      centre = CentreFinancier.create!(
        code: centre_financier_code,
        statut: 'non valide',
      )
      centre_financiers << centre
    end
  end

  def upcase_centre_financier_code
    self.centre_financier_code = centre_financier_code.upcase if centre_financier_code.present?
  end

  def calculate_delai_traitement_if_needed
    # Calculer les délais selon l'état final
    case etat
    when 'clôturé'
      calculate_delai_traitement if saved_change_to_etat? || date_cloture.blank?
    when 'clôturé après pré-instruction'
      calculate_delai_traitement_pre_instruction if saved_change_to_etat?
    when 'en pré-instruction', 'en cours d\'instruction'
      # renvoie en pré-instruction, instruction
      update_columns(
        date_cloture: nil,
        delai_traitement: nil,
        decision_finale: nil,
        valideur: nil,
      )
    end
  end

  def calculate_delai_traitement
    return unless etat == 'clôturé' && date_chorus.present? && date_cloture.present?

    delai_total = (date_cloture.to_date - date_chorus.to_date).to_i

    delai_final = if suspensions.empty?
                    delai_total
                  elsif type_acte == 'avis'
                    # Pour les avis, soustraire la durée de chaque suspension
                    duree_suspensions = suspensions.sum do |suspension|
                      if suspension.date_suspension.present? && suspension.date_reprise.present?
                        (suspension.date_reprise.to_date - suspension.date_suspension.to_date).to_i
                      else
                        0
                      end
                    end
                    [delai_total - duree_suspensions, 0].max
                  elsif %w[visa TF].include?(type_acte)
                    # Pour les visas, prendre le délai entre la dernière reprise et la clôture
                    derniere_suspension = suspensions.order(date_reprise: :desc).first
                    if derniere_suspension&.date_reprise.present?
                      (date_cloture.to_date - derniere_suspension.date_reprise.to_date).to_i
                    else
                      delai_total
                    end
                  else
                    delai_total
                  end

    update_columns(
      delai_traitement: delai_final,
    )
  end

  def calculate_delai_traitement_pre_instruction
    return unless etat == 'clôturé après pré-instruction'

    update_columns(
      date_cloture: Date.today,
      delai_traitement: (Date.today - created_at.to_date).to_i,
    )
  end

  def purge_pdf_files_on_update
    # Supprimer les PDF existants si l'acte a été modifié (sauf si c'est une création)
    return if new_record? || !saved_changes?

    # Ne pas supprimer si c'est juste le statut de génération qui change
    # ou si c'est juste updated_at (arrive lors de l'attachement d'un PDF)
    # (cela arrive quand on lance la génération ou quand le job met à jour le statut)
    changed_keys = saved_changes.keys.sort
    return if changed_keys == ['pdf_generation_status', 'updated_at'].sort
    return if changed_keys == ['pdf_generation_status']
    return if changed_keys == ['updated_at']

    # Supprimer tous les PDF attachés si présents
    if pdf_attached?
      pdf_files.purge
      Rails.logger.info "PDFs supprimés pour l'acte #{numero_formate} suite à une modification"
    end

    # Réinitialiser le statut de génération si ce n'est pas 'none'
    # (car l'acte a été modifié, le PDF n'est plus à jour)
    if pdf_generation_status != 'none'
      update_column(:pdf_generation_status, 'none')
    end
  end
end
