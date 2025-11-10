class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:synthese_utilisateurs, :ajout_actes, :import]
  before_action :authenticate_dcb_or_cbr, only: [:index, :new, :create, :edit, :update, :destroy]
  before_action :set_acte_ht2, only: [:edit, :update, :show, :destroy, :show_modal, :modal_delete,:modal_cloture_preinstruction, :cloture_pre_instruction, :modal_pre_instruction, :modal_renvoie_instruction, :modal_validate_acte, :modal_renvoie_validation]
  before_action :set_variables_form, only: [:edit, :modal_validate_acte]
  before_action :set_variables_filtres, only: [:index, :historique, :tableau_de_bord, :synthese_temporelle, :synthese_anomalies]
  before_action :set_actes_user, only: [:historique, :tableau_de_bord, :synthese_temporelle, :synthese_anomalies]
  before_action :set_parent_for_clone, only: :new
  before_action :check_edit_conditions, only: :edit
  require 'axlsx'
  include Ht2ActesHelper

  def index
    @selected_tab = params[:tab] || 'validation'

    # actes année en cours
    base_scope = current_user.ht2_actes.actifs_annee_courante.includes(:suspensions).order(updated_at: :desc)

    # liste de travail en cours
    @actes = base_scope.non_clotures
    @q_current = @actes.ransack(params[:q_current], search_key: :q_current)
    @actes_filtered = @q_current.result(distinct: true)
    # Instances par onglet (comptes/rows mis à jour uniquement par q_current)
    @actes_pre_instruction_all      = @actes_filtered.en_pre_instruction
    @actes_instruction_all          = @actes_filtered.en_cours_instruction
    @actes_suspendu_all             = @actes_filtered.suspendus
    @actes_validation_all           = @actes_filtered.en_attente_validation
    @actes_validation_chorus_all    = @actes_filtered.a_cloturer

    @pagy_pre_instruction,     @actes_pre_instruction     = pagy(@actes_pre_instruction_all,     page_param: :page_pre_instruction,     limit: 15)
    @pagy_instruction,         @actes_instruction         = pagy(@actes_instruction_all,         page_param: :page_instruction,         limit: 15)
    @pagy_suspendu,            @actes_suspendu            = pagy(@actes_suspendu_all,            page_param: :page_suspendu,            limit: 15)
    @pagy_validation,          @actes_validation          = pagy(@actes_validation_all,          page_param: :page_validation,          limit: 10)
    @pagy_validation_chorus,   @actes_validation_chorus   = pagy(@actes_validation_chorus_all,   page_param: :page_validation_chorus,   limit: 15)

    # actes clotures
    @actes_closed = base_scope.clotures
    @q_cloture = @actes_closed.ransack(params[:q_cloture], search_key: :q_cloture)
    @actes_cloture_all = @q_cloture.result(distinct: true)
    @pagy_cloture, @actes_cloture = pagy(@actes_cloture_all, page_param: :page_cloture, limit: 15)
    @filtres_count = count_active_filters(params[:q_cloture])
    respond_to do |format|
      format.html
      format.xlsx do
        scope = params[:scope].presence || 'current'
        @actes = scope == 'closed' ? @actes_cloture_all : @actes_filtered
      end
    end
  end

  def historique
    @q = @ht2_actes.ransack(params[:q])
    # Gestion du tri
    sort_order = params.dig(:q, :s) || 'updated_at desc'
    @actes_all = @q.result.includes(:user, :suspensions, centre_financier_principal: :programme).order(sort_order)
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
      @acte = current_user.ht2_actes.new(@acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'numero_chorus', 'etat', 'annee'))
      @acte.etat = @acte_parent.etat == "en pré-instruction" ? @acte_parent.etat : "en cours d'instruction"
      @acte.annee = Date.today.year
    elsif params[:parent_id].present? # nouvelle saisine avec même numéro chorus
      @acte = current_user.ht2_actes.new(@acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'date_chorus', 'etat','montant_ae', 'montant_global', 'type_engagement', 'annee'))
      @acte.etat = "en cours d'instruction"
      @acte.annee = Date.today.year
      @saisine = true
    else
      type_acte = params[:type_acte].present? && ['avis', 'visa', 'TF'].include?(params[:type_acte]) ? params[:type_acte] : 'visa'
      etat = params[:etat].present? && ['en pré-instruction', "en cours d'instruction"].include?(params[:etat]) ? params[:etat] : "en cours d'instruction"
      type_engagement = type_acte == "TF" ? 'Affectation initiale' : 'Engagement initial'
      pre_instruction = params[:pre_instruction] == 'true'
      @acte = current_user.ht2_actes.new(type_acte: type_acte, etat: etat, type_engagement: type_engagement, pre_instruction: pre_instruction)
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
        notice = update_acte_notice(@acte.etat, @etape)
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

    redirect_to ht2_actes_path, notice: "Actes clôturés avec succès."
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
    notice = update_acte_notice(@acte.etat, 0)
    redirect_to ht2_acte_path(@acte), notice: notice
  end

  def modal_renvoie_instruction; end
  def modal_renvoie_validation; end

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

  def modal_validate_acte; end

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
    search_params = params[:q] || {}
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if search_params[:annee_in].blank?
      search_params[:annee_in] = Date.today.year
    end

    @q = @ht2_actes.where(etat: ['clôturé','clôturé après pré-instruction']).ransack(search_params)
    @actes_filtered = @q.result(distinct: true)

    @actes_cloture = @actes_filtered.where(etat: 'clôturé')

    # Données pour le graphique pie
    @decisions_data = @actes_cloture.group_by(&:decision_finale).transform_values(&:count).map { |decision, count| { name: decision || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    @natures_data = @actes_cloture.group_by(&:nature).transform_values(&:count).map { |nature, count| { name: nature || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    @ordonnateurs_data = @actes_cloture.group_by(&:ordonnateur).transform_values(&:count).map { |ordonnateur, count| { name: ordonnateur || 'Non renseigné', y: count } }.sort_by { |h| -h[:y] }
    # Données pour le graphique des programmes
    @programmes_data = @actes_cloture.includes(centre_financier_principal: :programme)
                                      .group_by(&:programme_principal)
                                      .transform_values(&:count)
                                      .map { |programme, count| { name: programme&.numero || 'Non renseigné', y: count } }
    #.sort_by { |h| -h[:y] } # Tri du plus grand au plus petit
    # Répartition état/pré-instruction (SIMPLE)
    @preinstruction_data = [
      { name: "Clôturé sans pré-instruction", y: @actes_filtered.where(etat: "clôturé", pre_instruction: false).count },
      { name: "Clôturé avec pré-instruction", y: @actes_filtered.where(etat: "clôturé", pre_instruction: true).count },
      { name: "Clôturé en pré-instruction", y: @actes_filtered.where(etat: "clôturé après pré-instruction").count }
    ]
  end

  def synthese_temporelle
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    search_params = params[:q] || {}
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if search_params[:annee_eq].blank?
      search_params[:annee_eq] = Date.today.year
    end

    @q = @ht2_actes.where(etat: ['clôturé','clôturé après pré-instruction']).ransack(search_params)
    @actes_filtered = @q.result(distinct: true)
    @actes_par_mois = @actes_filtered.group_by_month(:date_cloture).count.map { |mois, count| [mois.strftime('%B %Y'), count] }
  end

  def synthese_anomalies
    # Initialiser les paramètres de recherche avec l'année en cours par défaut
    search_params = params[:q] || {}
    # Si aucun filtre d'année n'est spécifié, utiliser l'année en cours
    if search_params[:annee_in].blank?
      search_params[:annee_in] = Date.today.year
    end

    @q = @ht2_actes.ransack(search_params)
    @actes_filtered = @q.result.includes(:suspensions)

    @interruptions = @actes_filtered.where(type_acte: 'avis').map(&:suspensions).flatten.uniq
    @suspensions = @actes_filtered.where(type_acte: ['visa','TF']).map(&:suspensions).flatten.uniq
    @suspensions_all = @actes_filtered.map(&:suspensions).flatten.uniq
    @suspensions_data = @suspensions_all.group_by(&:motif).transform_values(&:count).map { |motif, count| { name: motif, y: count } }.sort_by { |h| -h[:y] }

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
    #TODO
    actes = Ht2Acte.where(etat: 'en attente de validation Chorus')
    actes.update_all(etat: 'à clôturer')
    actes_2 = Ht2Acte.where(etat: 'en attente de validation')
    actes_2.update_all(etat: 'à valider')
    suspensions_motif = Suspension.where(motif: 'Conformité des pièces')
    suspensions_motif.update_all(motif: "Non conformité des pièces")
    suspensions_2 = Suspension.where(motif: "Demande de mise en cohérence EJ /PJ (pôle 2)")
    suspensions_2.update_all(motif: "Demande de mise en cohérence EJ /PJ")
    avis = Ht2Acte.where(type_engagement: 'Engagement initial')
    avis.update_all(type_engagement: "Engagement initial prévisionnel")
    avis_2 = Ht2Acte.where(type_engagement: 'Engagement complémentaire')
    avis_2.update_all(type_engagement: "Engagement complémentaire prévisionnel")
  end

  def import
    Ht2Acte.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to ajout_actes_path }
    end
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
                                     :categorie, :numero_marche, :services_votes,:type_engagement,:programmation_prevue,
                                     :groupe_marchandises, type_observations: [],
                                     suspensions_attributes: [:id, :_destroy, :date_suspension, :motif, :observations],
                                     echeanciers_attributes: [:id, :_destroy, :annee, :montant_ae, :montant_cp],
                                     poste_lignes_attributes: [:id, :_destroy, :numero, :centre_financier_code, :montant, :domaine_fonctionnel, :fonds, :compte_budgetaire, :code_activite, :axe_ministeriel, :flux, :groupe_marchandises])
  end

  def set_acte_ht2
    @acte = Ht2Acte.find(params[:id])
  end

  def set_variables_form
    if (params[:type_acte].present? && params[:type_acte] == 'avis') || @acte&.type_acte == 'avis'
      @liste_natures = ['Accord cadre à bons de commande', 'Accord cadre à marchés subséquents', 'Autre contrat', 'Convention', "Liste d'actes",'Marché subséquent à bons de commande', 'Transaction', 'Autre']
      @liste_decisions = ['Favorable', 'Favorable avec observations', 'Défavorable', 'Retour sans décision (sans suite)', 'Saisine a posteriori']
      @liste_types_observations = ["Acte déjà signé par l’ordonnateur","Acte non soumis au contrôle", 'Compatibilité avec la programmation', 'Construction de l’EJ', 'Disponibilité des crédits', 'Évaluation de la consommation des crédits', 'Fondement juridique',"Hors périmètre du CBR/DCB", 'Imputation', 'Pièce(s) manquante(s)', "Problème dans la rédaction de l'acte", 'Risque au titre de la RGP', 'Saisine a posteriori', 'Saisine en dessous du seuil de soumission au contrôle', 'Autre']
      @liste_engagements = ['Engagement initial prévisionnel', 'Engagement complémentaire prévisionnel']
    elsif (params[:type_acte].present? && params[:type_acte] == 'visa') || @acte&.type_acte == 'visa'
      @liste_natures = ['Autre contrat', 'Bail', 'Bon de commande', 'Convention', 'Décision diverse', 'Dotation en fonds propres', "Liste d'actes", 'Marché unique', 'Marché à tranches', 'Marché mixte', 'MAPA unique', 'MAPA à tranches', 'MAPA à bons de commande', 'MAPA mixte', 'Prêt ou avance', 'Remboursement de mise à disposition T3', 'Subvention', "Subvention pour charges d'investissement", 'Subvention pour charges de service public', 'Transaction', 'Transfert', 'Autre']
      @liste_decisions = ['Visa accordé', 'Visa accordé avec observations', 'Refus de visa', 'Retour sans décision (sans suite)', 'Saisine a posteriori']
      @liste_types_observations = ["Acte déjà signé par l’ordonnateur", "Acte non soumis au contrôle",'Compatibilité avec la programmation', 'Construction de l’EJ', 'Disponibilité des crédits', 'Évaluation de la consommation des crédits', 'Fondement juridique',"Hors périmètre du CBR/DCB", 'Imputation', 'Pièce(s) manquante(s)', "Problème dans la rédaction de l'acte", 'Risque au titre de la RGP', 'Saisine a posteriori', 'Saisine en dessous du seuil de soumission au contrôle', 'Autre']
      @liste_engagements = ['Engagement initial', 'Engagement complémentaire', "Retrait d'engagement"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'TF') || @acte&.type_acte == 'TF'
      @liste_decisions = ['Visa accordé', 'Visa accordé avec observations', 'Refus de visa', 'Retour sans décision (sans suite)', 'Saisine a posteriori']
      @liste_types_observations = ["Acte déjà signé par l’ordonnateur", "Acte non soumis au contrôle", 'Compatibilité avec la programmation', 'Disponibilité des crédits', 'Évaluation de la consommation des crédits', 'Fondement juridique', 'Imputation',"Hors périmètre du CBR/DCB", 'Pièce(s) manquante(s)', "Problème dans la rédaction de l'acte", 'Risque au titre de la RGP', 'Saisine a posteriori', 'Saisine en dessous du seuil de soumission au contrôle', 'Autre']
      @liste_engagements = ['Affectation initiale', 'Affectation complémentaire', 'Retrait']
    end
    @liste_motifs_suspension = ['Défaut du circuit d’approbation Chorus', "Demande de mise en cohérence EJ /PJ", 'Erreur d’imputation', 'Erreur dans la construction de l’EJ', 'Mauvaise évaluation de la consommation des crédits', 'Pièce(s) manquante(s)','Non conformité des pièces', 'Problématique de compatibilité avec la programmation', 'Problématique de disponibilité des crédits', 'Problématique de soutenabilité', 'Saisine a posteriori', 'Autre']
    @categories = ['23','3','31','32','4','41','42','43','5','51','52','53','6','61','62','63','64','65','7','71','72','73']
  end

  def set_variables_filtres
    @liste_natures = [
      'Accord cadre à bons de commande',
      'Accord cadre à marchés subséquents',
      'Affectation complémentaire',
      'Affectation initiale',
      'Autre',
      'Autre contrat',
      'Avenant',
      'Bail',
      'Bon de commande',
      'Convention',
      'Décision diverse',
      'Dotation en fonds propres',
      "Liste d'actes",
      'MAPA à bons de commande',
      'MAPA à tranches',
      'MAPA mixte',
      'MAPA unique',
      'Marché à tranches',
      'Marché mixte',
      'Marché unique',
      'Prêt ou avance',
      'Remboursement de mise à disposition T3',
      'Retrait',
      'Subvention',
      "Subvention pour charges d'investissement",
      'Subvention pour charges de service public',
      'Transaction',
      'Transfert'
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
    redirect_to edit_ht2_acte_path(@acte, etape: 2) and return if @acte.disponibilite_credits.nil? && @etape == 3
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

      suspensions_count = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).count

      {
        user: user,
        actes_clotures_count: actes_clotures.count,
        actes_non_clotures_count: actes_non_clotures.count,
        actes_avec_suspensions_count: actes_avec_suspensions_count,
        suspensions_count: suspensions_count,
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

    count = 0

    # Filtres de type tableau
    count += Array(q_params[:type_acte_in]).reject(&:blank?).size
    count += Array(q_params[:annee_in]).reject(&:blank?).size
    count += Array(q_params[:etat_in]).reject(&:blank?).size
    count += Array(q_params[:decision_finale_in]).reject(&:blank?).size
    count += Array(q_params[:services_votes_in]).reject(&:blank?).size

    # Filtres de type texte/select
    count += 1 if q_params[:numero_formate_or_numero_chorus_cont].present?
    count += 1 if q_params[:nature_eq].present?
    count += 1 if q_params[:user_nom_eq].present?
    count += 1 if q_params[:centre_financier_code_cont].present?
    count += 1 if q_params[:beneficiaire_cont].present?
    count += 1 if q_params[:activite_cont].present?
    count += 1 if q_params[:date_cloture_gteq].present?
    count += 1 if q_params[:date_cloture_lteq].present?
    count += 1 if q_params[:date_chorus_gteq].present?
    count += 1 if q_params[:date_chorus_lteq].present?
    count += 1 if q_params[:montant_ae_gteq].present?  # Ajout
    count += 1 if q_params[:montant_ae_lteq].present?  # Ajout

    count
  end

  def set_parent_for_clone
    key = params[:id].presence || params[:parent_id].presence
    return unless key
    # utilise find_by! si tu ne veux pas borner à l'utilisateur:
    @acte_parent = current_user.ht2_actes.find(key)
  end
end
