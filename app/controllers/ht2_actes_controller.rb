class Ht2ActesController < ApplicationController
  include Ht2ActesHelper

  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:synthese_utilisateurs, :ajout_actes, :import]
  before_action :authenticate_dcb_or_cbr, only: [:index, :new, :create, :edit, :update, :destroy, :acte_actions]
  before_action :set_acte_ht2, only: [:edit, :update, :show, :destroy, :show_modal, :modal_delete,:modal_cloture_preinstruction, :cloture_pre_instruction, :modal_pre_instruction, :renvoie_instruction, :validate_acte, :modal_renvoie_validation, :acte_actions, :generate_pdf]
  before_action :set_variables_form, only: [:edit, :validate_acte]
  before_action :set_variables_filtres, only: [:index, :historique, :tableau_de_bord, :synthese_temporelle, :synthese_anomalies, :synthese_suspensions]
  before_action :set_actes_user, only: [:historique, :tableau_de_bord, :synthese_temporelle, :synthese_anomalies, :synthese_suspensions]
  before_action :set_parent_for_clone, only: :new
  before_action :check_edit_conditions, only: :edit
  require 'axlsx'
  include Ht2ActesHelper

  def index
    @selected_tab = params[:tab] || 'validation'

    # actes année en cours
    base_scope = current_user.ht2_actes.actifs_annee_courante.includes(:suspensions).order(updated_at: :desc)

    # Tous les actes avec filtres unifiés
    @actes = base_scope

    # On duplique pour ne pas modifier params directement
    search_params_current = (params[:q_current] || {}).dup

    # Gestion du filtre "Acte clôturé hors délai"
    hors_delai_values = Array(search_params_current.delete(:delai_traitement_hors_delai_in))

    if hors_delai_values.include?('oui') && !hors_delai_values.include?('non')
      # uniquement "Oui" → délai > 15 jours
      search_params_current[:delai_traitement_gt] = 15
    elsif hors_delai_values.include?('non') && !hors_delai_values.include?('oui')
      # uniquement "Non" → délai <= 15 jours
      search_params_current[:delai_traitement_lteq] = 15
    end

    # Gestion du filtre "Type d'observation"
    type_observations_values = Array(search_params_current.delete(:type_observations_array_in))

    # Gestion du filtre "Suspensions"
    suspensions_count_values = Array(search_params_current.delete(:suspensions_count_in))

    @q_current = @actes.ransack(search_params_current, search_key: :q_current)
    @actes_filtered = @q_current.result(distinct: true)

    # Appliquer le filtre type_observations si présent
    if type_observations_values.present?
      @actes_filtered = @actes_filtered.where("type_observations && ARRAY[?]::varchar[]", type_observations_values)
    end

    # Appliquer le filtre suspensions si présent
    if suspensions_count_values.present?
      acte_ids = []

      if suspensions_count_values.include?('aucune')
        # Actes sans suspension
        acte_ids += @actes_filtered.left_joins(:suspensions)
                                   .where(suspensions: { id: nil })
                                   .reorder('')
                                   .pluck('ht2_actes.id')
      end

      if suspensions_count_values.include?('1')
        # Actes avec exactement 1 suspension
        acte_ids += @actes_filtered.joins(:suspensions)
                                   .group('ht2_actes.id')
                                   .having('COUNT(suspensions.id) = 1')
                                   .reorder('')
                                   .pluck('ht2_actes.id')
      end

      if suspensions_count_values.include?('2_ou_plus')
        # Actes avec 2 suspensions ou plus
        acte_ids += @actes_filtered.joins(:suspensions)
                                   .group('ht2_actes.id')
                                   .having('COUNT(suspensions.id) >= 2')
                                   .reorder('')
                                   .pluck('ht2_actes.id')
      end

      @actes_filtered = @actes_filtered.where(id: acte_ids.uniq)
    end
    # Instances par onglet (comptes/rows mis à jour uniquement par q_current)
    # Tri avec Ransack pour actes en pré-instruction
    @q_pre_instruction = @actes_filtered.en_pre_instruction.ransack(params[:q_pre_instruction], search_key: :q_pre_instruction)
    @actes_pre_instruction_all      = @q_pre_instruction.result(distinct: true)

    # Tri avec Ransack pour actes en cours d'instruction
    @q_instruction = @actes_filtered.en_cours_instruction.ransack(params[:q_instruction], search_key: :q_instruction)
    @actes_instruction_all          = @q_instruction.result(distinct: true)

    # Tri avec Ransack pour actes suspendus
    @q_suspendu = @actes_filtered.suspendus.ransack(params[:q_suspendu], search_key: :q_suspendu)
    @actes_suspendu_all             = @q_suspendu.result(distinct: true)

    # Tri avec Ransack pour actes à valider
    @q_validation = @actes_filtered.en_attente_validation.ransack(params[:q_validation], search_key: :q_validation)
    @actes_validation_all           = @q_validation.result(distinct: true)

    # Tri avec Ransack pour actes à clôturer
    @q_validation_chorus = @actes_filtered.a_cloturer.ransack(params[:q_validation_chorus], search_key: :q_validation_chorus)
    @actes_validation_chorus_all    = @q_validation_chorus.result(distinct: true)

    @pagy_pre_instruction,     @actes_pre_instruction     = pagy(@actes_pre_instruction_all,     page_param: :page_pre_instruction,     limit: 15)
    @pagy_instruction,         @actes_instruction         = pagy(@actes_instruction_all,         page_param: :page_instruction,         limit: 15)
    @pagy_suspendu,            @actes_suspendu            = pagy(@actes_suspendu_all,            page_param: :page_suspendu,            limit: 15)
    @pagy_validation,          @actes_validation          = pagy(@actes_validation_all,          page_param: :page_validation,          limit: 10)
    @pagy_validation_chorus,   @actes_validation_chorus   = pagy(@actes_validation_chorus_all,   page_param: :page_validation_chorus,   limit: 15)

    # actes clotures (utilise maintenant @actes_filtered avec les mêmes filtres que les autres onglets)
    # Tri avec Ransack pour actes clôturés
    @q_cloture = @actes_filtered.clotures.ransack(params[:q_cloture], search_key: :q_cloture)
    @actes_cloture_all = @q_cloture.result(distinct: true).includes(:user, :suspensions, centre_financier_principal: :programme)
    @pagy_cloture, @actes_cloture = pagy(@actes_cloture_all, page_param: :page_cloture, limit: 15)
    @filtres_count = count_active_filters(params[:q_current])
    respond_to do |format|
      format.html
      format.xlsx do
        scope = params[:scope].presence || 'current'
        @actes = case scope
                 when 'closed'
                   @actes.clotures.includes(:user, :suspensions, centre_financier_principal: :programme)
                 when 'non_closed'
                   @actes.non_clotures.includes(:user, :suspensions, centre_financier_principal: :programme)
                 when 'all'
                   @actes.includes(:user, :suspensions, centre_financier_principal: :programme)
                 else
                   @actes.includes(:user, :suspensions, centre_financier_principal: :programme)
                 end
      end
    end
  end

  def historique
    # On duplique pour ne pas modifier params directement
    search_params = (params[:q] || {}).dup

    # Gestion du filtre "Acte clôturé hors délai"
    hors_delai_values = Array(search_params.delete(:delai_traitement_hors_delai_in))

    if hors_delai_values.include?('oui') && !hors_delai_values.include?('non')
      # uniquement "Oui" → délai > 15 jours
      search_params[:delai_traitement_gt] = 15
    elsif hors_delai_values.include?('non') && !hors_delai_values.include?('oui')
      # uniquement "Non" → délai <= 15 jours
      search_params[:delai_traitement_lteq] = 15
    end
    # si les deux ou aucun sont cochés → pas de condition particulière

    # Gestion du filtre "Type d'observation"
    type_observations_values = Array(search_params.delete(:type_observations_array_in))

    # Gestion du filtre "Suspensions"
    suspensions_count_values = Array(search_params.delete(:suspensions_count_in))

    @q = @ht2_actes.ransack(search_params)
    # Gestion du tri
    sort_order = params.dig(:q, :s) || 'updated_at desc'
    @actes_all = @q.result.includes(:user, :suspensions, centre_financier_principal: :programme).order(sort_order)

    # Appliquer le filtre type_observations si présent
    if type_observations_values.present?
      @actes_all = @actes_all.where("type_observations && ARRAY[?]::varchar[]", type_observations_values)
    end

    # Appliquer le filtre suspensions si présent
    if suspensions_count_values.present?
      acte_ids = []

      if suspensions_count_values.include?('aucune')
        # Actes sans suspension
        acte_ids += @actes_all.left_joins(:suspensions)
                              .where(suspensions: { id: nil })
                              .reorder('')
                              .pluck('ht2_actes.id')
      end

      if suspensions_count_values.include?('1')
        # Actes avec exactement 1 suspension
        acte_ids += @actes_all.joins(:suspensions)
                              .group('ht2_actes.id')
                              .having('COUNT(suspensions.id) = 1')
                              .reorder('')
                              .pluck('ht2_actes.id')
      end

      if suspensions_count_values.include?('2_ou_plus')
        # Actes avec 2 suspensions ou plus
        acte_ids += @actes_all.joins(:suspensions)
                              .group('ht2_actes.id')
                              .having('COUNT(suspensions.id) >= 2')
                              .reorder('')
                              .pluck('ht2_actes.id')
      end

      @actes_all = @actes_all.where(id: acte_ids.uniq)
    end

    @filtres_count = count_active_filters(params[:q])

    respond_to do |format|
      format.html do
        @pagy, @actes = pagy(@actes_all, limit: 20)
      end
      format.xlsx do
        # @actes_all contient déjà tous les résultats filtrés
        # Pas besoin de pagination pour l'export
      end
    end
  end

  def new
    if params[:id].present? # nouveau modèle
      @acte = current_user.ht2_actes.new(@acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'numero_chorus', 'etat', 'montant_ae', 'montant_global', 'numero_utilisateur', 'numero_formate', 'date_limite', 'decision_finale', 'delai_traitement', 'valideur', 'date_cloture', 'user_id'))
      @acte.etat = @acte_parent.etat == "en pré-instruction" ? @acte_parent.etat : "en cours d'instruction"

      # Duplication des poste_lignes
      @acte_parent.poste_lignes.each do |poste_ligne|
        @acte.poste_lignes.build(poste_ligne.attributes.except('id', 'created_at', 'updated_at', 'ht2_acte_id'))
      end

      # Duplication des écheanciers
      @acte_parent.echeanciers.each do |echeancier|
        @acte.echeanciers.build(echeancier.attributes.except('id', 'created_at', 'updated_at', 'ht2_acte_id'))
      end
    elsif params[:parent_id].present? # nouvelle saisine avec même numéro chorus
      @acte = current_user.ht2_actes.new(@acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'date_chorus', 'etat','montant_ae', 'montant_global', 'type_engagement', 'annee', 'numero_utilisateur', 'numero_formate', 'date_limite', 'decision_finale', 'delai_traitement', 'valideur', 'date_cloture', 'user_id'))
      @acte.etat = "en cours d'instruction"
      @acte.annee = Date.today.year
      @saisine = true

      # Duplication des poste_lignes
      @acte_parent.poste_lignes.each do |poste_ligne|
        @acte.poste_lignes.build(poste_ligne.attributes.except('id', 'created_at', 'updated_at', 'ht2_acte_id'))
      end

      # Duplication des écheanciers
      @acte_parent.echeanciers.each do |echeancier|
        @acte.echeanciers.build(echeancier.attributes.except('id', 'created_at', 'updated_at', 'ht2_acte_id'))
      end
    else
      type_acte = params[:type_acte].present? && ['avis', 'visa', 'TF'].include?(params[:type_acte]) ? params[:type_acte] : 'visa'
      etat = params[:etat].present? && ['en pré-instruction', "en cours d'instruction"].include?(params[:etat]) ? params[:etat] : "en cours d'instruction"
      type_engagement = type_acte == "TF" ? 'Affectation initiale' : 'Engagement initial'
      pre_instruction = params[:pre_instruction] == 'true'
      perimetre = params[:perimetre].present? && ['etat', 'organisme'].include?(params[:perimetre]) ? params[:perimetre] : 'etat'
      categorie_organisme = params[:categorie_organisme].present? && ['depense', 'recette'].include?(params[:categorie_organisme]) ? params[:categorie_organisme] : nil
      @acte = current_user.ht2_actes.new(type_acte: type_acte, etat: etat, type_engagement: type_engagement, pre_instruction: pre_instruction, perimetre: perimetre, categorie_organisme: categorie_organisme)
    end
    set_variables_form
  end

  def create
    @acte = current_user.ht2_actes.new(ht2_acte_params)
    @acte.nature = "TF" if @acte.type_acte == "TF"
    if @acte.save
      # Association du centre financier dans model after save
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :new
    end
  end

  def edit; end

  def update
    @etape = params[:etape].to_i || 1
    if @acte.update(ht2_acte_params)
      # after save : Mise à jour du centre financier si nécessaire + Calcul des délais de traitement
      if @etape <= 3 && ["en cours d'instruction", "suspendu", "en pré-instruction"].include?(@acte.etat)
        redirect_to edit_ht2_acte_path(@acte, etape: @etape)
      else
        notice = update_acte_notice(@acte.etat, @etape, @acte.type_acte)
        redirect_to ht2_acte_path(@acte), notice: notice
      end
    else
      render :edit
    end
  end

  def bulk_cloture
    ids = params[:acte_ids].flat_map { |id| id.to_s.split(',') }.map(&:strip).map(&:to_i)
    date = params[:date_cloture]
    redirect_to ht2_actes_path and return if date.nil?

    Ht2Acte.where(id: ids).find_each do |acte|
      acte.update(date_cloture: date, etat: "clôturé")
    end

    redirect_to ht2_actes_path(tab: 'clotures'), notice: "Actes clôturés avec succès."
  end

  def show
    @actes_groupe = @acte.numero_chorus.present? ? @acte.tous_actes_meme_chorus.includes(:suspensions, :echeanciers, :poste_lignes).order(annee: :asc, created_at: :asc) : [@acte]
    @acte_courant = @acte
  end

  def new_modal; end

  def show_modal; end

  def modal_delete; end

  def modal_cloture_preinstruction; end

  def modal_pre_instruction; end

  def cloture_pre_instruction
    @acte.update(etat: "clôturé après pré-instruction")
    notice = update_acte_notice(@acte.etat, 0, @acte.type_acte)
    redirect_to ht2_acte_path(@acte), notice: notice
  end

  def renvoie_instruction
    @frame_id = params[:frame_id] || view_context.dom_id(@acte, :bloc)
  end
  def validate_acte
    @frame_id = params[:frame_id] || view_context.dom_id(@acte, :bloc)
  end
  def modal_renvoie_validation; end
  def acte_actions
    @frame_id = params[:frame_id] || view_context.dom_id(@acte, :bloc)
  end

  # export fiche excel d'un acte
  def export
    @acte = Ht2Acte.find(params[:id])
    respond_to do |format|
      format.html
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=\"acte_#{@acte.numero_formate}_#{Date.current.strftime('%Y%m%d')}.xlsx\""
      end
      format.pdf do
        begin
          render pdf: "acte_ht2_#{@acte.numero_utilisateur}",
                 template: 'ht2_actes/export_pdf',
                 layout: 'pdf',
                 formats: [:html],
                 disposition: 'inline',
                 show_as_html: params[:debug].present?,
                 javascript_delay: 2000,
                 window_status: 'ready',
                 enable_javascript: true,
                 enable_local_file_access: true,
                 orientation: 'Portrait',
                 page_size: 'A4',
                 margin: { top: 15, bottom: 15, left: 10, right: 10 },
                 no_stop_slow_scripts: true,
                 timeout: 60 # Increase timeout to 60 seconds
        rescue => e
          Rails.logger.error("PDF generation error in export_pdf action: #{e.message}")
          Rails.logger.error(e.backtrace.join("\n"))
          flash[:error] = "Une erreur est survenue lors de la génération du PDF. Veuillez réessayer plus tard."
          redirect_to ht2_acte_path(@acte)
        end
      end
    end
  end

  def destroy
    @acte&.destroy
    redirect_to ht2_actes_path, notice: "Acte supprimé avec succès."
  end

  def check_chorus_number
    numero_chorus = params[:numero_chorus]
    acte_id = params[:acte_id]
    if numero_chorus.present?
      actes_meme_chorus = current_user.ht2_actes.where(numero_chorus: numero_chorus)
      actes_meme_chorus = actes_meme_chorus.where.not(id: acte_id) if acte_id.present?
      actes_meme_chorus_count = actes_meme_chorus.count
    else
      actes_meme_chorus_count = 0
    end
    render json: { exists: actes_meme_chorus_count.positive? }
  end

  def synthese
    @statut_user = current_user.statut
    # Récupérer tous les programmes disponibles pour le filtre
    @programmes = if @statut_user == 'admin'
                    Programme.all.order(numero: :asc)
                  else
                    Programme.joins(centre_financiers: { ht2_actes: :user })
                             .where(ht2_actes: { user_id: current_user.id })
                             .distinct
                             .order(numero: :asc)
                  end
    # chargement des actes en fonction du profil
    @ht2_actes = @statut_user == 'admin' ? Ht2Acte : current_user.ht2_actes
    # Filtrer par année
    @selected_year = params[:year].presence&.to_i || Date.current.year
    @ht2_actes = @ht2_actes.where(annee: @selected_year)
    # Récupérer le programme sélectionné (s'il y en a un)
    @selected_programme_id = params[:programme_id].presence
    # Filtrer par programme si un programme est sélectionné
    if @selected_programme_id.present?
      @ht2_actes = @ht2_actes.joins(centre_financiers: :programme)
                             .where(centre_financiers: { programme_id: @selected_programme_id })
    end
    # Précharger les associations nécessaires
    @ht2_actes = @ht2_actes.includes(:suspensions)
    # Réutiliser la même scope pour les actes clôturés
    @ht2_actes_clotures = @ht2_actes.where(etat: 'clôturé')
    # graphes
    @ht2_avis_decisions = @ht2_actes_clotures.where(type_acte: 'avis').group(:decision_finale).count
    @ht2_visa_decisions = @ht2_actes_clotures.where(type_acte: 'visa').group(:decision_finale).count
    @ht2_tf_decisions = @ht2_actes_clotures.where(type_acte: 'TF').group(:decision_finale).count
    @ht2_suspensions_motif = calculate_suspensions_stats(@ht2_actes_clotures)
    @actes_par_mois = calculate_actes_par_mois(@ht2_actes, @statut_user == 'admin', @selected_year)
    @suspensions_distribution = calculate_suspensions_distribution(@ht2_actes_clotures)
    @top_suspension_motifs_chart_data = calculate_top_motifs(@ht2_actes_clotures)
    # Construire la requête agrégée
    top_programmes = Programme
                       .select('programmes.id, programmes.numero, COUNT(ht2_actes.id) AS actes_count')
                       .joins(centre_financiers: :ht2_actes)
                       .merge(@ht2_actes_clotures)
                       .group('programmes.id')
                       .order('actes_count DESC')
                       .limit(10)
    @top_programmes_chart_data = top_programmes.map { |p| { name: p.numero, y: p.actes_count.to_i } }
    top_programmes_suspensions = Programme
                                   .select('programmes.id, programmes.numero, COUNT(suspensions.id) AS suspensions_count')
                                   .joins(centre_financiers: { ht2_actes: :suspensions })
                                   .merge(@ht2_actes_clotures)
                                   .group('programmes.id')
                                   .order('suspensions_count DESC')
                                   .limit(10)
    @top_programmes_suspensions_chart_data = top_programmes_suspensions.map { |p| { name: p.numero, y: p.suspensions_count.to_i } }

    if @statut_user == 'admin'
      @stacked_type_acte_data = calculate_repartion(@ht2_actes_clotures)
    else
      @repartition_acte = @ht2_actes_clotures.group(:type_acte).count.map { |type_acte, count| { name: type_acte, y: count } }
    end
  end
  def tableau_de_bord
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    @all_actes_user = @ht2_actes.clotures_seuls
    q = params[:q] || {}
    @q_params = (q.respond_to?(:to_unsafe_h) ? q.to_unsafe_h : q).deep_dup

    # Supprimer les paramètres vides
    @q_params.reject! { |_, v| v.blank? }
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if @q_params[:annee_eq].blank?
      @q_params[:annee_eq] = Date.today.year
    end

    @q = @ht2_actes.clotures.ransack(@q_params)
    @actes_filtered = @q.result(distinct: true) #pour graphes pre instruction
    @actes_cloture = @actes_filtered.clotures_seuls
    @total_actes = @actes_cloture.count

    # Données pour le graphique pie
    @type_actes = @actes_cloture.group_by(&:type_acte).transform_values(&:count).map { |type, count| { name: type || 'Non renseigné', y: count } }.sort_by { |h| h[:name].to_s.downcase }
    @decisions_data = @actes_cloture.group_by(&:decision_finale).transform_values(&:count).map { |decision, count| { name: decision || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    @natures_data = @actes_cloture.group_by(&:nature).transform_values(&:count).map { |nature, count| { name: nature || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    @ordonnateurs_data = @actes_cloture.group_by(&:ordonnateur).transform_values(&:count).map { |ordonnateur, count| { name: ordonnateur || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    # Données pour le graphique des programmes
    @programmes_data = @actes_cloture.includes(centre_financier_principal: :programme)
                                      .group_by(&:programme_principal)
                                      .transform_values(&:count)
                                      .map { |programme, count| { name: programme&.numero || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] } # Tri du plus grand au plus petit
    # Répartition état/pré-instruction (SIMPLE)
    @preinstruction_data = [
      { name: "Clôturé sans pré-instruction", y: @actes_filtered.where(etat: "clôturé", pre_instruction: false).count },
      { name: "Clôturé avec pré-instruction", y: @actes_filtered.where(etat: "clôturé", pre_instruction: true).count },
      { name: "Clôturé en pré-instruction", y: @actes_filtered.where(etat: "clôturé après pré-instruction").count }
    ]

    year = @q_params[:annee_eq].to_i
    start_date = Date.new(year, 1, 1)
    end_date   = start_date.end_of_year

    # 1) Comptages bruts par mois
    recus_raw = @actes_cloture
                  .where(date_chorus: start_date..end_date)
                  .group("EXTRACT(MONTH FROM date_chorus)")
                  .count
    recus_by_month = recus_raw.transform_keys(&:to_i)

    clotures_raw = @actes_cloture
                     .where(date_cloture: start_date..end_date)
                     .group("EXTRACT(MONTH FROM date_cloture)")
                     .count
    clotures_by_month = clotures_raw.transform_keys(&:to_i)

    # ---- 3. Construire les tableaux 12 valeurs (janvier..décembre)
    recus_array = (1..12).map { |m| recus_by_month[m] || 0 }
    clotures_array = (1..12).map { |m| clotures_by_month[m] || 0 }

    @actes_par_mois = {
      categories: I18n.t('date.month_names')[1..12], # ["janvier", ..., "décembre"]
      series: [
        { name: "Actes reçus",    y: recus_array },    # 12 valeurs
        { name: "Actes clôturés", y: clotures_array }  # 12 valeurs
      ]
    }

    # Regrouper par année et type_acte
    @counts = @all_actes_user.group(:annee, :type_acte).count
    # => { [2022, "avis"] => 813, [2023, "avis"] => 623, ... }

    @years = (2024..Date.today.year).to_a
    types = @counts.keys.map(&:last).uniq.sort

    @evolution_par_annee = {
      categories: @years,
      series: types.map do |type|
        {
          name: type || 'Non renseigné',
          y: @years.map { |year| @counts[[year, type]] || 0 }
        }
      end
    }
  end

  def synthese_temporelle
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    q = params[:q] || {}
    @q_params = (q.respond_to?(:to_unsafe_h) ? q.to_unsafe_h : q).deep_dup
    # Supprimer les paramètres vides
    @q_params.reject! { |_, v| v.blank? }
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if @q_params[:annee_eq].blank?
      @q_params[:annee_eq] = Date.today.year
    end

    @q = @ht2_actes.clotures_seuls.ransack(@q_params)
    @actes_filtered = @q.result(distinct: true)

    year = @q_params[:annee_eq].to_i
    # 12 mois basés sur la date_cloture
    delais_par_mois = (1..12).map do |month|
      actes_du_mois = @actes_filtered.where(
        date_cloture: Date.new(year, month, 1)..Date.new(year, month, -1)
      )

      if actes_du_mois.any?
        (actes_du_mois.average(:delai_traitement).to_f).round(1)
      else
        0  # ou 0 si tu préfères
      end
    end

    @delais_dataset = {
      categories: I18n.t("date.month_names")[1..12], # ["janvier", ..., "décembre"]
      series: [
        {
          name: "Délai moyen de traitement (jours)",
          y: delais_par_mois
        }
      ]
    }

    # Calcul du délai moyen de traitement par programme
    delais_par_programme = @actes_filtered
      .includes(centre_financier_principal: :programme)
      .group('programmes.numero')
      .average(:delai_traitement)
      .reject { |k, v| k.nil? || v.nil? } # Filtrer les programmes null et valeurs null
      .transform_values { |v| v.to_f.round(1) } # Convertir explicitement en float
      .sort_by { |_k, v| -v }
      .to_h

    @delais_par_programme_dataset = {
      categories: delais_par_programme.keys,
      series: [
        {
          name: "Délai moyen (jours)",
          y: delais_par_programme.values # Les valeurs sont maintenant des float
        }
      ]
    }
  end

  def synthese_suspensions
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    q = params[:q] || {}
    @q_params = (q.respond_to?(:to_unsafe_h) ? q.to_unsafe_h : q).deep_dup
    # Supprimer les paramètres vides
    @q_params.reject! { |_, v| v.blank? }
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if @q_params[:annee_eq].blank?
      @q_params[:annee_eq] = Date.today.year
    end

    @q = @ht2_actes.ransack(@q_params)
    @actes_filtered = @q.result.includes(:suspensions)
    @suspensions_all = @actes_filtered.map(&:suspensions).flatten.uniq
    @suspensions_all_count = @suspensions_all.count
    @suspensions_data = @suspensions_all.group_by(&:motif).transform_values(&:count).map { |motif, count| { name: motif, y: count } }.sort_by { |h| -h[:y] }
    # Calcul du nombre de suspensions par programme
    suspensions_par_programme = @actes_filtered
                                  .joins(:suspensions)
                                  .joins(centre_financier_principal: :programme)
                                  .group('programmes.numero')
                                  .order('COUNT(suspensions.id) DESC')
                                  .pluck('programmes.numero', 'COUNT(suspensions.id)')
                                  .to_h

    @suspensions_par_programme_dataset = {
      categories: suspensions_par_programme.keys,
      series: [
        {
          name: "Nombre de suspensions",
          y: suspensions_par_programme.values
        }
      ]
    }

    # Calcul de l'évolution pluriannuelle des suspensions
    years = (2024..Date.today.year).to_a
    suspensions_par_annee = @ht2_actes
                              .joins(:suspensions)
                              .where(annee: years)
                              .group(:annee)
                              .order(:annee)
                              .count('suspensions.id')

    # S'assurer que toutes les années sont présentes, même avec 0 suspension
    suspensions_values = years.map { |year| suspensions_par_annee[year] || 0 }

    @evolution_suspensions_dataset = {
      categories: years,
      series: [
        {
          name: "Nombre de suspensions",
          y: suspensions_values
        }
      ]
    }
  end

  def synthese_anomalies
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    q = params[:q] || {}
    @q_params = (q.respond_to?(:to_unsafe_h) ? q.to_unsafe_h : q).deep_dup
    # Supprimer les paramètres vides
    @q_params.reject! { |_, v| v.blank? }
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if @q_params[:annee_eq].blank?
      @q_params[:annee_eq] = Date.today.year
    end

    @q = @ht2_actes.ransack(@q_params)
    @actes_filtered = @q.result.includes(:suspensions)

    # Données pour les observations - Utilise unnest de PostgreSQL
    all_observations =
      @actes_filtered
        .pluck(:type_observations)
        .compact
        .flat_map { |v| v.is_a?(String) ? (v.strip.start_with?('[') ? JSON.parse(v) : [v]) : Array(v) }
        .map { |s| s.to_s.strip }
        .reject(&:blank?)

    @observations_data = all_observations
                                 .tally
                                 .map { |name, count| { name: name, y: count } }
                                 .sort_by { |h| -h[:y] }

    @total_observations = all_observations.size

    # Calcul de l'évolution pluriannuelle des observations
    years = (2024..Date.today.year).to_a
    observations_par_annee = {}

    years.each do |year|
      actes_annee = @ht2_actes.where(annee: year)
      observations_count = actes_annee
        .pluck(:type_observations)
        .compact
        .flat_map { |v| v.is_a?(String) ? (v.strip.start_with?('[') ? JSON.parse(v) : [v]) : Array(v) }
        .reject(&:blank?)
        .size
      observations_par_annee[year] = observations_count
    end

    # S'assurer que toutes les années sont présentes
    observations_values = years.map { |year| observations_par_annee[year] || 0 }

    @evolution_observations_dataset = {
      categories: years,
      series: [
        {
          name: "Nombre d'observations",
          y: observations_values
        }
      ]
    }

    # Calcul du nombre d'observations par programme
    observations_par_programme = {}

    @actes_filtered.includes(centre_financier_principal: :programme).each do |acte|
      programme_numero = acte.centre_financier_principal&.programme&.numero
      next unless programme_numero

      # Compter les observations de cet acte
      observations_count = if acte.type_observations.present?
        obs = acte.type_observations
        if obs.is_a?(String)
          obs.strip.start_with?('[') ? JSON.parse(obs).size : 1
        elsif obs.is_a?(Array)
          obs.reject(&:blank?).size
        else
          0
        end
      else
        0
      end

      observations_par_programme[programme_numero] ||= 0
      observations_par_programme[programme_numero] += observations_count
    end

    # Retirer les programmes avec 0 observations et trier par nombre décroissant
    observations_par_programme = observations_par_programme.reject { |_k, v| v == 0 }.sort_by { |_k, v| -v }.to_h

    @observations_par_programme_dataset = {
      categories: observations_par_programme.keys,
      series: [
        {
          name: "Nombre d'observations",
          y: observations_par_programme.values
        }
      ]
    }
  end
  def synthese_utilisateurs
    @users_cbr = User.where(statut: 'CBR').order(nom: :asc)
    @users_dcb = User.where(statut: 'DCB').order(nom: :asc)

    @stats_cbr = user_ht2_stats(@users_cbr)
    @stats_dcb = user_ht2_stats(@users_dcb)
  end

  def download_attachments
    @acte = Ht2Acte.find(params[:id])

    # Extraire les attachments du rich text
    attachments = extract_attachments_from_rich_text(@acte.commentaire_disponibilite_credits)

    if attachments.empty?
      redirect_back(fallback_location: ht2_acte_path(@acte), alert: "Aucune image trouvée dans les observations.")
      return
    end

    # Si une seule image, télécharger directement
    if attachments.size == 1
      attachment = attachments.first
      send_data attachment.download,
                filename: attachment.filename.to_s,
                type: attachment.content_type,
                disposition: 'attachment'
      return
    end

    # Si plusieurs images, créer un ZIP
    zip_data = create_zip_with_attachments(attachments, @acte.id)

    send_data zip_data,
              filename: "acte_#{@acte.id}_images_#{Date.current.strftime('%Y%m%d')}.zip",
              type: 'application/zip',
              disposition: 'attachment'

  end

  def ajout_actes
    # Récupérer tous les utilisateurs avec leurs statistiques pour 2025
    @users_stats = User.all.order(:nom).map do |user|
      actes_2025_count = user.ht2_actes.where(annee: 2025).count
      {
        user: user,
        actes_2025_count: actes_2025_count
      }
    end.select { |stat| stat[:actes_2025_count] > 0 } # Ne garder que les users avec des actes en 2025
  end

  def delete_user_actes_year
    user = User.find(params[:user_id])
    year = params[:year].to_i

    actes_count = user.ht2_actes.where(annee: year).count
    user.ht2_actes.where(annee: year).destroy_all

    redirect_to ajout_actes_path, notice: "#{actes_count} actes de l'année #{year} pour #{user.nom} ont été supprimés."
  end

  def import
    Ht2Acte.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to ajout_actes_path }
    end
  end

  def generate_pdf
    # Définir le statut comme "en cours de génération"
    @acte.update(pdf_generation_status: 'generating')

    # Lancer la génération du PDF avec notification au centre une fois terminé
    GenerateActePdfJob.perform_later(@acte.id)

    redirect_to ht2_acte_path(@acte),
                notice: "Le PDF est en cours de création. #{view_context.link_to('Réactualisez la page', ht2_acte_path(@acte))} dans quelques instants pour pouvoir télécharger le document.".html_safe
  end

  private

  def ht2_acte_params
    params[:ht2_acte][:type_observations] = params[:ht2_acte][:type_observations]&.split(',') if params[:ht2_acte][:type_observations].is_a?(String)

    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :numero_tf, :date_limite,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :observations,
                                     :user_id, :commentaire_disponibilite_credits, :valideur, :date_cloture, :annee,
                                     :decision_finale, :numero_utilisateur, :numero_formate, :delai_traitement, :sheet_data,
                                     :categorie, :numero_marche, :services_votes, :liste_actes, :nombre_actes, :type_engagement,:programmation_prevue,
                                     :groupe_marchandises,:renvoie_instruction,:pdf_generation_status, :perimetre, :categorie_organisme, :nom_organisme,
                                     :type_montant, :operation_compte_tiers, :operation_budgetaire, :nature_categorie_organisme, :budget_executoire,
                                     :deliberation_ca, :numero_deliberation_ca, :date_deliberation_ca, :observations_deliberation_ca, :destination, :nomenclature, :flux,
                                     :soutenabilite, :conformite, :concordance_recettes_tiers, :autorisation_tutelle, type_observations: [],
                                     suspensions_attributes: [:id, :_destroy, :date_suspension, :motif, :observations],
                                     echeanciers_attributes: [:id, :_destroy, :annee, :montant_ae, :montant_cp],
                                     poste_lignes_attributes: [:id, :_destroy, :numero, :centre_financier_code, :montant, :domaine_fonctionnel, :fonds, :compte_budgetaire, :code_activite, :axe_ministeriel, :flux, :groupe_marchandises, :numero_tf])
  end

  def set_acte_ht2
    @acte = Ht2Acte.find(params[:id])
  end

  def set_variables_form
    # Gestion spécifique pour le périmètre organisme
    perimetre = params[:perimetre] || @acte&.perimetre
    categorie_organisme = params[:categorie_organisme] || @acte&.categorie_organisme
    type_acte = params[:type_acte] || @acte&.type_acte

    if perimetre == 'organisme' && categorie_organisme == 'depense'
      @liste_natures = [
        "Accord cadre à bons de commande",
        "Acquisition d'œuvres",
        "Acquisition immobilière",
        "Attribution de garanties",
        "Autre contrat",
        "Bail",
        "Bon de commande",
        "Conseil",
        "Convention",
        "Décision diverse",
        "Emprunt autorisé",
        "Intervention",
        "Marché à tranches",
        "Marché mixte",
        "Marché subséquent à bons de commande",
        "Marché unique",
        "MAPA à tranches",
        "MAPA mixte",
        "MAPA unique",
        "Participation et apport à toute entité",
        "Prêt ou avance",
        "Remboursement de mise à disposition T3",
        "Subvention",
        "Transaction",
        "Autre"
      ]
      # Pour organisme dépense, @liste_engagements dépend du type_acte
      @liste_engagements = ["Engagement initial","Engagement initial prévisionnel", "Engagement complémentaire","Engagement complémentaire prévisionnel", "Retrait d'engagement"]
      @liste_types_observations = ["Acte non soumis au contrôle", "Compatibilité avec la programmation", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Hors périmètre du CBR/DCB", "Impact à prendre en compte dans le prochain budget", "Imputation", "Pièce(s) manquante(s)", "Problème dans la rédaction de l'acte", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
    elsif perimetre == 'organisme' && categorie_organisme == 'recette'
      @liste_natures = [
        "Aliénation immobilière",
        "Cession de participation et retrait d’apport à toute entité",
        "Convention et contrat en recette",
        "Autre"
      ]
      # Pour organisme recette, pas de @liste_engagements
      @liste_types_observations = ["Acte non soumis au contrôle", "Fondement juridique", "Hors périmètre du CBR/DCB", "Impact à prendre en compte dans le prochain budget", "Imputation", "Pièce(s) manquante(s)", "Problème dans la rédaction de l'acte", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'avis') || @acte&.type_acte == 'avis'
      @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Convention", "Marché subséquent à bons de commande", "MAPA à bons de commande", "Transaction", "Autre"]
      @liste_types_observations = ["Acte non soumis au contrôle", "Compatibilité avec la programmation", "Construction de l'EJ", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Hors périmètre du CBR/DCB", "Imputation", "Pièce(s) manquante(s)", "Problème dans la rédaction de l'acte", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
      @liste_engagements = ["Engagement initial prévisionnel", "Engagement complémentaire prévisionnel"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'visa') || @acte&.type_acte == 'visa'
      @liste_natures = ["Autre contrat", "Bail", "Bon de commande", "Convention", "Décision diverse", "Dotation en fonds propres", "Marché unique", "Marché à tranches", "Marché mixte", "MAPA unique", "MAPA à tranches", "MAPA mixte", "Prêt ou avance", "Remboursement de mise à disposition T3", "Subvention", "Subvention pour charges d'investissement", "Subvention pour charges de service public", "Transaction", "Transfert", "Autre"]
      @liste_types_observations = ["Acte non soumis au contrôle", "Compatibilité avec la programmation", "Construction de l'EJ", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Hors périmètre du CBR/DCB", "Imputation", "Pièce(s) manquante(s)", "Problème dans la rédaction de l'acte", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
      @liste_engagements = ["Engagement initial", "Engagement complémentaire", "Retrait d'engagement"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'TF') || @acte&.type_acte == 'TF'
      @liste_types_observations = ["Acte non soumis au contrôle", "Compatibilité avec la programmation", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Hors périmètre du CBR/DCB", "Pièce(s) manquante(s)", "Problème dans la rédaction de l'acte", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
      @liste_engagements = ["Affectation initiale", "Affectation complémentaire", "Retrait"]
    end

    # @liste_decisions définie uniquement en fonction du type_acte
    if type_acte == 'avis'
      @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    else
      @liste_decisions = ["Visa accordé", "Visa accordé avec observations", "Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    end

    # @liste_motifs_suspension définie en fonction du périmètre
    if perimetre == 'organisme' && categorie_organisme == 'depense'
      @liste_motifs_suspension = ["Demande de précisions", "Erreur d'imputation", "Mauvaise évaluation de la consommation des crédits", "Non conformité des pièces", "Pièce(s) manquante(s)", "Problématique de compatibilité avec la programmation", "Problématique de disponibilité des crédits", "Problématique de soutenabilité", "Saisine a posteriori", "Autre"]
    elsif perimetre == 'organisme' && categorie_organisme == 'recette'
      @liste_motifs_suspension = ["Demande d'éléments complémentaires", "Demande de précisions", "Erreur d'imputation", "Non conformité des pièces", "Pièce(s) manquante(s)", "Saisine a posteriori", "Autre"]
    else
      # Liste pour périmètre état (liste par défaut)
      @liste_motifs_suspension = ["Défaut du circuit d'approbation Chorus", "Demande d'éléments complémentaires", "Demande de mise en cohérence EJ /PJ", "Erreur d'imputation", "Erreur dans la construction de l'EJ", "Mauvaise évaluation de la consommation des crédits", "Pièce(s) manquante(s)", "Non conformité des pièces", "Problématique de compatibilité avec la programmation", "Problématique de disponibilité des crédits", "Problématique de soutenabilité", "Saisine a posteriori", "Autre"]
    end
    @categories = ['23','3','31','32','4','41','42','43','5','51','52','53','6','61','62','63','64','65','7','71','72','73']
  end

  def set_variables_filtres
    @liste_natures = [
      "Accord cadre à bons de commande",
      "Accord cadre à marchés subséquents",
      "Acquisition d'œuvres",
      "Acquisition immobilière",
      "Aliénation immobilière",
      "Attribution de garanties",
      "Autre",
      "Autre contrat",
      "Bail",
      "Bon de commande",
      "Cession de participation et retrait d'apport à toute entité",
      "Conseil",
      "Convention",
      "Convention et contrat en recette",
      "Décision diverse",
      "Dotation en fonds propres",
      "Emprunt autorisé",
      "Intervention",
      "MAPA à bons de commande",
      "MAPA à tranches",
      "MAPA mixte",
      "MAPA unique",
      "Marché à tranches",
      "Marché mixte",
      "Marché subséquent à bons de commande",
      "Marché unique",
      "Participation et apport à toute entité",
      "Prêt ou avance",
      "Remboursement de mise à disposition T3",
      "Subvention",
      "Subvention pour charges d'investissement",
      "Subvention pour charges de service public",
      "Transaction",
      "Transfert"
    ]
  end

  def set_actes_user
    @statut_user = current_user.statut
    # chargement des actes en fonction du profil
    @ht2_actes = @statut_user == 'admin' ? Ht2Acte : current_user.ht2_actes
  end

  def check_edit_conditions
    redirect_to ht2_actes_path and return unless ["en cours d'instruction", "suspendu", "en pré-instruction"].include?(@acte.etat)

    @etape = params[:etape].present? && [1, 2, 3].include?(params[:etape].to_i) ? params[:etape].to_i : 1

    # Vérifier que l'étape 2 est complète avant de passer à l'étape 3
    if @etape == 3
      redirect_to edit_ht2_acte_path(@acte, etape: 2) and return unless etape2_complete?(@acte)
    end
  end

  def calculate_suspensions_stats(actes)
    # Récupérer les statistiques des suspensions par type d'acte
    stats = []

    # Pour chaque type d'acte (visa et avis)
    ['avis', 'visa', 'TF'].each do |type_acte|
      # Trouver tous les actes de ce type
      actes_type = actes.where(type_acte: type_acte)

      # Obtenir toutes les suspensions liées à ces actes
      suspensions_ids = Suspension.where(ht2_acte_id: actes_type.pluck(:id)).pluck(:id)

      # Compter les occurrences de chaque motif
      motifs_count = Suspension.where(id: suspensions_ids).group(:motif).count

      # Formater les données pour le frontend
      motifs_data = motifs_count.map do |motif, count|
        { motif: motif, count: count }
      end

      # Ajouter les statistiques pour ce type d'acte
      stats << {
        type_acte: type_acte,
        total_suspensions: suspensions_ids.size,
        motifs: motifs_data
      }
    end

    stats
  end

  def calculate_actes_par_mois(actes, admin, year)
    # Obtenir l'année en cours
    current_year = year

    # Préparer un tableau pour chaque mois de l'année
    mois = (1..12).map do |month|
      debut_mois = Date.new(current_year, month, 1)
      fin_mois = Date.new(current_year, month, -1) # Dernier jour du mois
      if admin
        # Initialiser les compteurs par profil
        created_cbr = actes
                        .joins(:user)
                        .where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois)
                        .where(users: { statut: 'CBR' }).count

        created_dcb = actes
                        .joins(:user)
                        .where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois)
                        .where(users: { statut: 'DCB' }).count

        closed_cbr = actes
                       .joins(:user)
                       .where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                       .where(etat: 'clôturé', users: { statut: 'CBR' }).count

        closed_dcb = actes
                       .joins(:user)
                       .where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                       .where(etat: 'clôturé', users: { statut: 'DCB' }).count

        {
          mois: I18n.l(debut_mois, format: '%B'),
          created_cbr: created_cbr,
          created_dcb: created_dcb,
          closed_cbr: closed_cbr,
          closed_dcb: closed_dcb
        }
      else
        # Compter les actes créés ce mois
        actes_crees = actes.where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois).count

        # Compter les actes clôturés ce mois
        actes_clotures = actes.where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                              .where(etat: 'clôturé')
                              .count

        {
          mois: I18n.l(debut_mois, format: '%B'), # Nom du mois en français
          actes_crees: actes_crees,
          actes_clotures: actes_clotures
        }
      end
    end

    mois
  end

  def calculate_suspensions_distribution(actes)
    # Compter le nombre de suspensions pour chaque acte
    suspensions_par_acte = actes.map do |acte|
      acte.suspensions.count
    end

    # Trouver le nombre maximum de suspensions pour un acte
    max_suspensions = suspensions_par_acte.max || 0

    # Préparer le hash pour compter les actes par nombre de suspensions
    distribution = Hash.new(0)

    # Compter les actes pour chaque nombre de suspensions
    suspensions_par_acte.each do |count|
      distribution[count] += 1
    end

    # Transformer en tableau pour tous les nombres de 0 à max_suspensions
    result = []
    (0..max_suspensions).each do |i|
      result << {
        nombre_suspensions: i,
        nombre_actes: distribution[i]
      }
    end

    result
  end

  def calculate_repartion(actes)
    # Tous les ht2_actes visibles
    all_actes = actes
    dcb_actes = actes.joins(:user).where(users: { statut: 'DCB' })
    cbr_actes = actes.joins(:user).where(users: { statut: 'CBR' })

    # Regrouper par type_acte
    total_counts = all_actes.group(:type_acte).count
    dcb_counts = dcb_actes.group(:type_acte).count
    cbr_counts = cbr_actes.group(:type_acte).count

    # Types d'actes possibles (ajustable si dynamique)
    types_actes = ['TF', 'visa', 'avis']

    # Construire les séries pour Highcharts
    result = types_actes.map do |type|
      {
        name: type,
        data: [
          total_counts[type] || 0,
          dcb_counts[type] || 0,
          cbr_counts[type] || 0
        ]
      }
    end
    result
  end

  def calculate_top_motifs(actes)
    ht2_acte_ids = actes.pluck(:id)

    top_suspension_motifs = Suspension
                              .where(ht2_acte_id: ht2_acte_ids)
                              .group(:motif)
                              .order(Arel.sql('COUNT(*) DESC'))
                              .limit(5)
                              .count
    top_suspension_motifs_chart_data = top_suspension_motifs.map do |motif, count|
      {
        name: motif,
        y: count
      }
    end
    top_suspension_motifs_chart_data
  end

  def user_ht2_stats(users)
    users.includes(:ht2_actes).map do |user|
      ht2_actes = user.ht2_actes.annee_courante

      actes_clotures = ht2_actes.clotures
      actes_non_clotures = ht2_actes.non_clotures

      actes_avec_suspension_ids = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).pluck(:ht2_acte_id).uniq
      actes_avec_suspensions_count = actes_avec_suspension_ids.size

      #suspensions_count = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).count
      actes_avec_observations_count = actes_clotures.where.not(type_observations: []).count
      {
        user: user,
        actes_clotures_count: actes_clotures.count,
        actes_non_clotures_count: actes_non_clotures.count,
        actes_avec_suspensions_count: actes_avec_suspensions_count,
        actes_avec_observations_count: actes_avec_observations_count,
        delai_moyen: actes_clotures.delai_moyen_traitement,
      }
    end
  end

  # Méthode pour extraire les attachments d'un rich text
  def extract_attachments_from_rich_text(rich_text_content)
    return [] if rich_text_content.blank?

    attachments = []

    # Méthode 1: Utiliser les associations directes d'ActionText (le plus fiable)
    if rich_text_content.respond_to?(:embeds)
      Rails.logger.debug "Utilisation des embeds ActionText"
      attachments = rich_text_content.embeds.select(&:image?)
      Rails.logger.debug "Attachments trouvés via embeds: #{attachments.count}"
      return attachments unless attachments.empty?
    end
    attachments
  end

  # Méthode pour créer un ZIP avec les attachments
  def create_zip_with_attachments(attachments, acte_id)
    require 'zip'

    zip_data = Zip::OutputStream.write_buffer do |zip|
      attachments.each_with_index do |attachment, index|
        begin
          # Nom du fichier dans le ZIP
          filename = attachment.respond_to?(:filename) ? attachment.filename.to_s : "image_#{index + 1}"

          # Ajouter l'extension si elle manque
          unless filename.include?('.')
            extension = attachment.respond_to?(:content_type) ?
                          Marcel::MimeType.for(attachment.content_type).split('/').last : 'png'
            filename = "#{filename}.#{extension}"
          end

          # Télécharger et ajouter au ZIP
          file_data = attachment.respond_to?(:download) ? attachment.download : attachment.blob.download
          zip.put_next_entry("#{index + 1}_acte_#{acte_id}_#{filename}")
          zip.write(file_data)

        rescue => e
          Rails.logger.error "Erreur lors de l'ajout de #{attachment} au ZIP: #{e.message}"
        end
      end
    end

    zip_data.string
  end

  def count_active_filters(q_params)
    return 0 if q_params.blank?

    # On récupère un vrai hash
    q = q_params.respond_to?(:to_unsafe_h) ? q_params.to_unsafe_h : q_params
    q = q.deep_dup

    # On récupère les filtres "hors délai" puis on les retire du hash,
    # pour ne pas les compter deux fois comme filtres "classiques"
    delay_gt   = q.delete("delai_traitement_gt")   || q.delete(:delai_traitement_gt)
    delay_lteq = q.delete("delai_traitement_lteq") || q.delete(:delai_traitement_lteq)

    # On récupère le filtre "type d'observation" puis on le retire du hash
    type_observations = q.delete("type_observations_array_in") || q.delete(:type_observations_array_in)

    # On récupère le filtre "suspensions" puis on le retire du hash
    suspensions_count = q.delete("suspensions_count_in") || q.delete(:suspensions_count_in)

    # On ne considère pas le tri comme un filtre
    q.delete("s")
    q.delete(:s)

    # On ne compte pas les filtres de périmètre et de recherche (qui sont dans la barre principale)
    q.delete("perimetre_in")
    q.delete(:perimetre_in)
    q.delete("numero_formate_or_numero_chorus_or_centre_financier_code_or_instructeur_or_valideur_or_beneficiaire_or_activite_cont")
    q.delete(:numero_formate_or_numero_chorus_or_centre_financier_code_or_instructeur_or_valideur_or_beneficiaire_or_activite_cont)

    # Compte des filtres "classiques"
    count = q.count do |_k, v|
      case v
      when Array
        v.reject(&:blank?).any?
      else
        v.present?
      end
    end

    # Ajout de 1 si le filtre "hors délai" est activé
    count += 1 if delay_gt.present? || delay_lteq.present?

    # Ajout de 1 si le filtre "type d'observation" est activé
    count += 1 if type_observations.is_a?(Array) && type_observations.reject(&:blank?).any?

    # Ajout de 1 si le filtre "suspensions" est activé
    count += 1 if suspensions_count.is_a?(Array) && suspensions_count.reject(&:blank?).any?

    count
  end

  def set_parent_for_clone
    key = params[:id].presence || params[:parent_id].presence
    return unless key
    # utilise find_by! si tu ne veux pas borner à l'utilisateur:
    @acte_parent = current_user.ht2_actes.find(key)
  end
end
