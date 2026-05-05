class Ht2Acte < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :centre_financiers
  has_and_belongs_to_many :organismes
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
  accepts_nested_attributes_for :suspensions, reject_if: ->(attributes) { attributes['date_suspension'].blank? || Array(attributes['motif']).reject(&:blank?).empty? }, allow_destroy: true
  accepts_nested_attributes_for :echeanciers, reject_if: ->(attributes) { attributes['annee'].blank? || attributes['montant_ae'].blank? }, allow_destroy: true
  before_save :strip_organisme_and_cf_fields
  before_save :upcase_centre_financier_code
  after_save :set_etat_acte
  after_save :set_numero_utilisateur, if: :saved_change_to_annee?
  after_save :calculate_date_limite_if_needed
  after_save :associate_centre_financier_if_needed
  after_save :associate_organisme_if_needed
  after_save :calculate_delai_traitement_if_needed
  after_save :purge_pdf_files_on_update

  has_rich_text :commentaire_disponibilite_credits

  scope :en_attente_validation, -> { where(etat: ["à valider", "à suspendre"]) }
  scope :en_cours_instruction, -> { where(etat: ["en cours d'instruction"]) }
  scope :en_pre_instruction, -> { where(etat: ["en pré-instruction"]) }
  scope :suspendus, -> { where(etat: ["suspendu"]) }
  scope :a_cloturer, -> { where(etat: ["à clôturer"]) }
  scope :clotures, -> { where(etat: ['clôturé', 'clôturé en pré-instruction']) }
  scope :clotures_seuls, -> { where(etat: 'clôturé') }
  scope :clotures_apres_pre_instruction, -> { where(etat: 'clôturé en pré-instruction') }
  scope :non_clotures, -> { where.not(etat: ['clôturé', 'clôturé en pré-instruction']) }
  scope :annee_courante, -> { where(annee: Date.current.year) }
  scope :perimetre_etat, -> { where(perimetre: 'etat') }
  scope :perimetre_organisme, -> { where(perimetre: 'organisme') }
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
    ["action", "activite", "annee", "autorisation_tutelle", "avis_programmation", "beneficiaire", "budget_executoire", "categorie", "categorie_organisme", "centre_financier_code", "commentaire_proposition_decision", "concordance_recettes_tiers", "conformite", "consommation_credits", "created_at", "date_chorus", "date_cloture", "date_deliberation_ca", "date_limite", "decision_finale", "delai_traitement", "deliberation_ca", "destination", "disponibilite_credits", "etat", "flux", "gestion_anticipee", "groupe_marchandises", "id", "id_value", "imputation_depense", "instructeur", "liste_actes", "montant_ae", "montant_global", "nature", "nature_categorie_organisme", "nombre_actes", "nom_organisme", "nomenclature", "numero_chorus", "numero_deliberation_ca", "numero_formate", "numero_marche", "numero_tf", "numero_utilisateur", "objet", "observations", "observations_deliberation_ca", "operation_budgetaire", "operation_compte_tiers", "ordonnateur", "pdf_generation_status", "perimetre", "pre_instruction", "precisions_acte", "programmation", "programmation_prevue", "proposition_decision", "renvoie_instruction", "services_votes", "sheet_data", "sous_action", "soutenabilite", "type_acte", "type_engagement", "type_montant", "type_observations", "updated_at", "user_id", "valideur"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["centre_financier_principal", "centre_financiers", "echeanciers", "organismes", "poste_lignes", "rich_text_commentaire_disponibilite_credits", "suspensions", "user"]
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
    "clôturé en pré-instruction",
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

    query = Ht2Acte.where(numero_chorus: numero_chorus, user_id: user_id, perimetre: perimetre)

    # Ajouter le filtre sur categorie_organisme si le champ existe (périmètre organisme)
    if perimetre == 'organisme' && categorie_organisme.present?
      query = query.where(categorie_organisme: categorie_organisme, nom_organisme: nom_organisme)
    end

    query
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

  def last_suspension_date_reprise
    last_suspension&.date_reprise
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
    return nil if date_cloture.nil? || date_chorus.nil?
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

  def self.import_from_backup(file)
    data = Roo::Spreadsheet.open(file.path)

    # ── Onglet ht2_actes ──────────────────────────────────────────────────────
    actes_sheet = data.sheet('ht2_actes')
    actes_headers = actes_sheet.row(1).map { |h| h.to_s.strip }

    # id_map : ancien id (exporté) → nouvel id (créé en prod)
    id_map = {}

    actes_sheet.each_with_index do |row, idx|
      next if idx == 0
      r = Hash[actes_headers.zip(row)]

      old_id = r['id'].to_i
      user = User.find_by(nom: r['user_nom'].to_s.strip)
      next unless user

      bool = ->(v) { ['true', '1', 't'].include?(v.to_s.downcase) }
      parse_date = ->(v) {
        return nil if v.blank?
        v.is_a?(Date) || v.is_a?(Time) ? v.to_date : Date.strptime(v.to_s.strip, '%d/%m/%Y') rescue nil
      }
      parse_array = ->(v) { v.blank? ? [] : v.to_s.split(',').map(&:strip).reject(&:blank?) }

      acte = Ht2Acte.new(
        user:                             user,
        annee:                            r['annee'].to_i,
        type_acte:                        r['type_acte'],
        etat:                             r['etat'],
        perimetre:                        r['perimetre'],
        categorie_organisme:              r['categorie_organisme'],
        instructeur:                      r['instructeur'],
        valideur:                         r['valideur'],
        numero_formate:                   nil, # recalculé par set_numero_utilisateur
        numero_chorus:                    r['numero_chorus'].to_s,
        numero_marche:                    r['numero_marche'].to_s,
        numero_tf:                        r['numero_tf'].to_s,
        # numero_utilisateur : recalculé par set_numero_utilisateur (after_save)
        date_chorus:                      parse_date.(r['date_chorus']),
        date_limite:                      parse_date.(r['date_limite']),
        date_cloture:                     parse_date.(r['date_cloture']),
        # delai_traitement : recalculé par calculate_delai_traitement_if_needed (after_save)
        nature:                           r['nature'],
        nature_categorie_organisme:       r['nature_categorie_organisme'],
        beneficiaire:                     r['beneficiaire'],
        objet:                            r['objet'],
        ordonnateur:                      r['ordonnateur'],
        destination:                      r['destination'],
        montant_ae:                       r['montant_ae'].presence&.to_f,
        montant_global:                   r['montant_global'].presence&.to_f,
        type_montant:                     r['type_montant'],
        type_engagement:                  r['type_engagement'],
        centre_financier_code:            r['centre_financier_code'],
        groupe_marchandises:              r['groupe_marchandises'],
        nomenclature:                     r['nomenclature'],
        flux:                             r['flux'],
        activite:                         r['activite'],
        action:                           r['action'],
        sous_action:                      r['sous_action'],
        operation_budgetaire:             r['operation_budgetaire'],
        nom_organisme:                    r['nom_organisme'],
        categorie:                        r['categorie'],
        proposition_decision:             r['proposition_decision'],
        decision_finale:                  r['decision_finale'],
        commentaire_proposition_decision: r['commentaire_proposition_decision'],
        observations:                     r['observations'],
        type_observations:                parse_array.(r['type_observations']),
        precisions_acte:                  r['precisions_acte'],
        disponibilite_credits:            bool.(r['disponibilite_credits']),
        imputation_depense:               bool.(r['imputation_depense']),
        consommation_credits:             bool.(r['consommation_credits']),
        programmation:                    bool.(r['programmation']),
        programmation_prevue:             bool.(r['programmation_prevue']),
        avis_programmation:               r['avis_programmation'].blank? ? true : bool.(r['avis_programmation']),
        services_votes:                   bool.(r['services_votes']),
        liste_actes:                      bool.(r['liste_actes']),
        nombre_actes:                     r['nombre_actes'].presence&.to_i,
        gestion_anticipee:                bool.(r['gestion_anticipee']),
        pre_instruction:                  bool.(r['pre_instruction']),
        renvoie_instruction:              bool.(r['renvoie_instruction']),
        soutenabilite:                    r['soutenabilite'].blank? ? true : bool.(r['soutenabilite']),
        conformite:                       r['conformite'].blank? ? true : bool.(r['conformite']),
        concordance_recettes_tiers:       bool.(r['concordance_recettes_tiers']),
        autorisation_tutelle:             bool.(r['autorisation_tutelle']),
        budget_executoire:                r['budget_executoire'].blank? ? true : bool.(r['budget_executoire']),
        operation_compte_tiers:           bool.(r['operation_compte_tiers']),
        deliberation_ca:                  bool.(r['deliberation_ca']),
        numero_deliberation_ca:           r['numero_deliberation_ca'],
        date_deliberation_ca:             parse_date.(r['date_deliberation_ca']),
        observations_deliberation_ca:     r['observations_deliberation_ca'],
        pdf_generation_status:            'none',
      )

      if acte.save
        id_map[old_id] = acte.id
      else
        Rails.logger.warn "[import_from_backup] acte old_id=#{old_id} : #{acte.errors.full_messages.join(', ')}"
      end
    end

    # ── Onglet suspensions ────────────────────────────────────────────────────
    begin
      susp_sheet = data.sheet('suspensions')
      susp_headers = susp_sheet.row(1).map { |h| h.to_s.strip }

      susp_sheet.each_with_index do |row, idx|
        next if idx == 0
        r = Hash[susp_headers.zip(row)]

        old_acte_id = r['ht2_acte_id'].to_i
        new_acte_id = id_map[old_acte_id]
        next unless new_acte_id

        parse_date = ->(v) {
          return nil if v.blank?
          v.is_a?(Date) || v.is_a?(Time) ? v.to_date : Date.strptime(v.to_s.strip, '%d/%m/%Y') rescue nil
        }

        date_susp = parse_date.(r['date_suspension'])
        next unless date_susp

        motif = r['motif'].blank? ? ['Autre'] : r['motif'].to_s.split(',').map(&:strip).reject(&:blank?)

        Suspension.create!(
          ht2_acte_id:        new_acte_id,
          date_suspension:    date_susp,
          date_reprise:       parse_date.(r['date_reprise']),
          motif:              motif,
          observations:       r['observations'],
          commentaire_reprise: r['commentaire_reprise'],
        )
      end

      # Recalculer l'état des actes importés maintenant que leurs suspensions existent
      Ht2Acte.where(id: id_map.values).each do |acte|
        acte.send(:set_etat_acte)
      end
    rescue RangeError, Roo::UnsupportedFileType
      Rails.logger.warn "[import_from_backup] onglet suspensions introuvable ou vide"
    end

    # ── Onglet echeanciers ────────────────────────────────────────────────────
    begin
      ech_sheet = data.sheet('echeanciers')
      ech_headers = ech_sheet.row(1).map { |h| h.to_s.strip }

      ech_sheet.each_with_index do |row, idx|
        next if idx == 0
        r = Hash[ech_headers.zip(row)]

        old_acte_id = r['ht2_acte_id'].to_i
        new_acte_id = id_map[old_acte_id]
        next unless new_acte_id

        Echeancier.create!(
          ht2_acte_id: new_acte_id,
          annee:       r['annee'].to_i,
          montant_ae:  r['montant_ae'].presence&.to_f,
          montant_cp:  r['montant_cp'].presence&.to_f,
        )
      end
    rescue RangeError, Roo::UnsupportedFileType
      Rails.logger.warn "[import_from_backup] onglet echeanciers introuvable ou vide"
    end

    id_map
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
        montant_global: ["Engagement initial", "Affectation initiale"].include?(row_data["type_engagement"]) ? row_data["montant_ae"].presence&.to_f : row_data["montant_global"].presence&.to_f,
        centre_financier_code: row_data["centre_financier_code"],
        date_chorus: row_data["date_chorus"].is_a?(Date) ? row_data["date_chorus"] : nil,
        date_cloture: row_data["date_cloture"].is_a?(Date) ? row_data["date_cloture"] : nil,
        date_limite: row_data["date_limite"].is_a?(Date) ? row_data["date_limite"] : nil,
        numero_chorus: row_data["numero_chorus"].to_s,
        beneficiaire: row_data["beneficiaire"],
        objet: row_data["objet"],
        etat: row_data["decision_finale"].present? ? "clôturé" : "clôturé en pré-instruction",
        numero_tf: row_data["numero_tf"].to_s,
        numero_marche: row_data["numero_marche"].to_s,
        user: user,
        proposition_decision: row_data["proposition_decision"].present? ? row_data["proposition_decision"] : row_data["decision_finale"],
        decision_finale: row_data["decision_finale"],
        precisions_acte: row_data["precisions_acte"],
        valideur: row_data["valideur"].present? ? row_data["valideur"] : row_data["instructeur"],
        categorie: row_data["categorie"].to_s,
        activite: row_data["activite"].presence,
        action: row_data["action"].presence,
        groupe_marchandises: row_data["groupe_marchandises"].presence,
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
            motif: [row_data["motif"].presence || 'Autre']
          )
          # recalcul APRÈS les suspensions
          acte.recalculate_delai_traitement!
        end
      else
        Rails.logger.warn "Erreur à la ligne #{i} : #{acte.errors.full_messages.join(', ')}"
      end
    end
  end


  def self.import_actes_organismes(file)
    data = Roo::Spreadsheet.open(file.path)
    headers = data.row(1).map { |h| h.to_s.strip }

    bool     = ->(v) { ['oui', 'true', '1', 't'].include?(v.to_s.downcase.strip) }
    parse_date = ->(v) {
      return nil if v.blank?
      v.is_a?(Date) || v.is_a?(Time) ? v.to_date : Date.strptime(v.to_s.strip, '%d/%m/%Y') rescue nil
    }

    count = 0

    data.each_with_index do |row, idx|
      next if idx == 0

      r = Hash[headers.zip(row)]

      # Récupérer l'organisme à partir du nom
      nom_org = r['nom_organisme'].to_s.strip
      next if nom_org.blank?

      organisme = Organisme.find_by(nom: nom_org)
      next unless organisme

      # Construire nom_organisme au format "Acronyme - Nom" ou "Nom"
      nom_organisme_formate = if organisme.acronyme.present?
                                "#{organisme.acronyme} - #{organisme.nom}"
                              else
                                organisme.nom
                              end

      # Récupérer l'utilisateur
      user = User.find_by(nom: r['user_nom'].to_s.strip)
      next unless user

      acte = Ht2Acte.new(
        user:                             user,
        perimetre:                        'organisme',
        type_acte:                        r['type_acte'].to_s,
        categorie_organisme:              r['categorie_organisme'].to_s,
        etat:                             r['etat'].to_s,
        instructeur:                      r['instructeur'].to_s,
        nature:                           r['nature'].to_s,
        type_engagement:                  r['type_engagement'].to_s,
        operation_budgetaire:             r['operation_budgetaire'].to_s,
        nature_categorie_organisme:       r['nature_categorie_organisme'].to_s,
        nom_organisme:                    nom_organisme_formate,
        montant_ae:                       r['montant_ae'].presence&.to_f,
        type_montant:                     r['type_montant'].to_s,
        operation_compte_tiers:           bool.(r['operation_compte_tiers']),
        budget_executoire:                r['budget_executoire'].blank? ? true : bool.(r['budget_executoire']),
        annee:                            r['annee'].presence&.to_i,
        date_chorus:                      parse_date.(r['date_chorus']),
        services_votes:                   bool.(r['services_votes']),
        programmation_prevue:             bool.(r['programmation_prevue']),
        disponibilite_credits:            r['disponibilite_credits'].blank? ? true : bool.(r['disponibilite_credits']),
        imputation_depense:               r['imputation_depense'].blank? ? true : bool.(r['imputation_depense']),
        consommation_credits:             r['consommation_credits'].blank? ? true : bool.(r['consommation_credits']),
        soutenabilite:                    r['soutenabilite'].blank? ? true : bool.(r['soutenabilite']),
        conformite:                       r['conformite'].blank? ? true : bool.(r['conformite']),
        deliberation_ca:                  bool.(r['deliberation_ca']),
        programmation:                    bool.(r['programmation']),
        proposition_decision:             r['proposition_decision'].to_s,
        date_cloture:                     parse_date.(r['date_cloture'] || r['Date de cloture']),
        pre_instruction:                  bool.(r['Présence d\'une pré-instruction hors ANACO']),
        beneficiaire:                     r['Bénéficiaire'].to_s,
        objet:                            r['objet'].to_s,
        ordonnateur:                      r['ordonnateur'].to_s,
        liste_actes:                      false,
        destination:                      r['Destination'].to_s,
        nomenclature:                     r['Nomenclature achat'].to_s,
        flux:                             r['Flux'].to_s,
        numero_deliberation_ca:           r['n° de délibération'].to_s,
        date_deliberation_ca:             parse_date.(r['Date de délibération']),
        observations_deliberation_ca:     r['Observation sur la délibération en CA'].to_s,
        commentaire_proposition_decision: r['commentaire_proposition_decision'].to_s,
        observations:                     r['observations'].to_s,
        type_observations:                r['type_observations'].present? ? [r['type_observations'].to_s] : [],
        valideur:                         r['valideur'].to_s,
        decision_finale:                  r['decision_finale'].to_s,
        pdf_generation_status:            'none',
        precisions_acte:                  r['precisions'].to_s,
      )

      if acte.save
        count += 1
        date_susp = parse_date.(r['date_suspension'])
        if date_susp.present?
          motif = r['motif'].blank? ? ['Autre'] : r['motif'].to_s.split(',').map(&:strip).reject(&:blank?)
          acte.suspensions.create(
            date_suspension: date_susp,
            date_reprise:    parse_date.(r['date_reprise']),
            motif:           motif
          )
          acte.recalculate_delai_traitement!
        end
      else
        Rails.logger.warn "[import_actes_organismes] ligne #{idx + 1} : #{acte.errors.full_messages.join(', ')}"
      end
    end

    count
  end

  private

  def set_etat_acte
    if self.suspensions.present? && self.suspensions.last&.date_reprise.nil? && !["suspendu", "à suspendre"].include?(self.etat)
      update_column(:etat,"suspendu")
    elsif !etat.present? || !VALID_ETATS.include?(etat)
      update_column(:etat, "en cours d'instruction")
    elsif self.etat == "en pré-instruction"
      update_column(:pre_instruction , true)
    elsif ["suspendu", "à suspendre"].include?(self.etat) && self.suspensions.where(date_reprise: nil).empty?
      update_column(:etat, "en cours d'instruction")
    elsif self.etat == "clôturé" && self.decision_finale.nil?
      update_column(:decision_finale, self.proposition_decision)
    end
    if self.etat == "clôturé" && self.valideur.blank?
      update_column(:valideur, self.instructeur)
    end
    if self.etat == "clôturé en pré-instruction"
      update_column(:valideur, self.instructeur) if self.valideur.blank?
      update_column(:decision_finale, self.proposition_decision) if self.decision_finale.nil?
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

  def associate_organisme_if_needed
    # Vérifier si le nom_organisme a changé
    if saved_change_to_nom_organisme?
      associate_organisme
    end
  end

  def associate_organisme
    return unless nom_organisme.present?

    # Extraire le nom si le format est "acronyme - nom"
    nom_recherche = if nom_organisme.include?(' - ')
                      nom_organisme.split(' - ', 2).last.strip
                    else
                      nom_organisme
                    end

    organisme = Organisme.find_by(nom: nom_recherche)
    organismes.destroy_all
    if organisme
      # Supprimer les associations existantes et ajouter la nouvelle
      organismes << organisme
    end
  end

  def strip_organisme_and_cf_fields
    self.nom_organisme = nom_organisme.strip if nom_organisme.present?
    self.centre_financier_code = centre_financier_code.strip if centre_financier_code.present?
  end

  def upcase_centre_financier_code
    self.centre_financier_code = centre_financier_code.upcase if centre_financier_code.present?
  end

  def calculate_delai_traitement_if_needed
    # Calculer les délais selon l'état final
    case etat
    when 'clôturé'
      calculate_delai_traitement if saved_change_to_etat? || date_cloture.blank?
    when 'clôturé en pré-instruction'
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
    return unless etat == 'clôturé en pré-instruction'

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
