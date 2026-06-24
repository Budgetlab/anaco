# frozen_string_literal: true

# controller des Avis
class AvisController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:admin_back_up_avis, :import, :export_avis]
  before_action :redirect_unless_dcb, only: %i[consultation update_etat]
  before_action :set_bop, only: %i[new create edit update]
  before_action :redirect_unless_bop_controller, only: %i[new create edit update]
  before_action :set_liste_motifs, only: %i[new create edit update]
  require 'axlsx'
  include ApplicationHelper
  include AvisHelper
  include BopsHelper
  # Page historique des avis
  def index
    scope = current_user.statut == 'admin' ? Avi : current_user.avis
    avis_all = scope.order(updated_at: :desc)

    # On duplique pour ne pas modifier params directement
    search_params = (params[:q] || {}).dup

    # Par défaut, filtrer sur l'année en cours si aucun filtre n'est spécifié
    if params[:q].blank?
      search_params[:annee_in] = [Date.today.year.to_s]
    end

    # Exposer les params pour l'affichage des filtres dans la vue
    @q_params = search_params.respond_to?(:to_unsafe_h) ? search_params.to_unsafe_h.deep_dup : search_params.deep_dup

    @q = avis_all.ransack(search_params)
    @avis_all = @q.result.includes(bop: :programme, user: [])
    @filtres_count = count_active_filters(@q_params)
    respond_to do |format|
      format.html do
        @pagy, @avis_page = pagy(@avis_all, limit: 15)
      end
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=\"historique_avis_#{Date.today}.xlsx\""
      end
    end
  end

  # Page de création d'un nouvel avis
  def new
    @annee_a_afficher = annee_a_afficher
    # Activité par année : un BOP peut être actif globalement (statut) mais hors période
    # d'activité pour l'année ciblée → pas de saisie possible cette année-là.
    redirect_to bop_path(@bop) and return unless @bop.actif_en?(@annee_a_afficher)
    redirect_to edit_bop_path(@bop) and return if @bop.dotation.blank?

    set_avis_phase(@annee_a_afficher)
    # phase_id (instance précise de Phase) prime sur phase (string legacy),
    # qui prime sur la déduction automatique de set_form_phase.
    @phase_obj = Phase.find_by(id: params[:phase_id]) if params[:phase_id].present?
    @phase_form = @phase_obj&.nom || params[:phase].presence || set_form_phase(@annee_a_afficher)

    # Recherche du dernier avis pour cette phase : par phase_id si fourni (cible une
    # instance précise — SV1 ou SV2), sinon par nom (cas legacy / phase mono-instance).
    @last_avis_phase =
      if @phase_obj
        @bop.avis.where(annee: @annee_a_afficher, phase_id: @phase_obj.id).order(:created_at).last
      else
        @bop.avis.where(annee: @annee_a_afficher, phase: @phase_form).order(:created_at).last
      end

    if @last_avis_phase.present?
      # Avis existant non finalisé (brouillon) → reprendre
      unless ['Lu', 'En attente de lecture'].include?(@last_avis_phase.etat)
        redirect_to edit_bop_avi_path(bop_id: @bop.id, id: @last_avis_phase.id) and return
      end

      # Avis déjà finalisé et hors phase services votés (le seul formulaire multi-versions)
      # → on consulte le BOP plutôt que de doublonner.
      if @phase_form != 'services votés'
        redirect_to bop_path(@bop), notice: 'Un avis a déjà été transmis pour cette phase.' and return
      end
    end

    @avis = @bop.avis.new(phase_id: @phase_obj&.id)
  end

  # fonction qui créé un nouvel avis
  def create
    @avis = @bop.avis.new(force_non_recu_attributes!(avi_params))
    if @avis.save
      @message = params[:avi][:etat] == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
      @avis.update(etat: 'Lu') if dcb_is_updating?
      redirect_to historique_path, notice: @message
    else
      render :new
    end
  end

  def edit
    @avis = Avi.find(params[:id])
    @annee_a_afficher = @avis.annee
    set_avis_phase(@avis.annee)
    @phase_form = @avis.phase
  end

  def update
    @avis = Avi.find(params[:id])
    etat = @avis.etat
    forced_params = force_non_recu_attributes!(avi_params)
    if ['Lu', 'En attente de lecture'].include?(etat) # avis modifié
      @avis.update(forced_params)
      @avis.update(etat: etat) if @avis.etat != "Brouillon"
      redirect_to bop_path(@avis.bop), notice: 'Modification'
    elsif @avis.update(forced_params)
      @message = params[:avi][:etat] == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
      @avis.update(etat: 'Lu') if dcb_is_updating?
      redirect_to historique_path, notice: @message
    else
      render :edit
    end
  end

  def show
    @avis = Avi.find(params[:id])
  end

  def destroy
    @avis = Avi.find(params[:id])
    bop = @avis.bop
    if @avis.etat == 'Brouillon' && (@avis.user == current_user || current_user.statut == 'admin')
      @avis.destroy
      redirect_to bop_path(bop), notice: 'Brouillon supprimé'
    else
      redirect_to bop_path(bop), alert: 'Action non autorisée'
    end
  end

  # Page de consultation des avis pour les DCB
  def consultation
    bops_consultation = current_user.consulted_bops.where.not(user_id: current_user.id)
    avis_all = Avi.where(bop_id: bops_consultation.pluck(:id)).where.not(etat: 'Brouillon').order(created_at: :desc)

    # On duplique pour ne pas modifier params directement
    search_params = (params[:q] || {}).dup

    # Par défaut, filtrer sur l'année en cours si aucun filtre n'est spécifié
    if params[:q].blank?
      search_params[:annee_in] = [Date.today.year.to_s]
    end

    # Exposer les params pour l'affichage des filtres dans la vue
    @q_params = search_params.respond_to?(:to_unsafe_h) ? search_params.to_unsafe_h.deep_dup : search_params.deep_dup

    @q = avis_all.ransack(search_params)
    @avis_all = @q.result.includes(bop: :programme, user: [])
    @avis_en_attente = @avis_all.where(etat: 'En attente de lecture')
    @avis_lus = @avis_all.where(etat: 'Lu')
    @filtres_count = count_active_filters(@q_params)
    respond_to do |format|
      format.html do
        @pagy_en_attente, @avis_en_attente_page = pagy(@avis_en_attente, page_param: :page_en_attente, limit: 15)
        @pagy_lus, @avis_lus_page = pagy(@avis_lus,page_param: :page_lus, limit: 15)
      end
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=\"avis_lus_#{Date.today}.xlsx\""
      end
    end
  end

  # fonction qui met à jour l'état de l'avis comme Lu
  def update_etat
    if params[:id]
      @avis = Avi.find(params[:id])
      @avis&.update(etat: 'Lu')
      notice = 'Lu'
    else # update all
      bops_consultation = current_user.consulted_bops.where.not(user_id: current_user.id)
      avis = Avi.where(bop_id: bops_consultation.pluck(:id)).where(etat: 'En attente de lecture')
      avis.update_all(etat: 'Lu')
      notice = 'Lus'
    end
    redirect_to consultation_path, flash: { notice: notice }
  end

  def admin_back_up_avis
    @annees = Avi.distinct.pluck(:annee).compact.sort.reverse
    @counts = Avi.group(:annee).count
  end

  def export_avis
    annee = params[:annee].to_i
    @avis = Avi.where(annee: annee).includes(:bop, :user).order(:phase, :created_at)
    @annee = annee
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=\"avis_#{annee}_#{Date.today}.xlsx\""
      end
    end
  end

  def import
    Avi.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to admin_back_up_avis_path }
    end
  end

  def remplissage_avis
    @annee_a_afficher = annee_a_afficher
    @bops_inactifs = current_user.bops_inactifs(@annee_a_afficher).order(code: :asc)
    @bops_actifs = current_user.bops_actifs(@annee_a_afficher).order(code: :asc)
    @avis = current_user.avis.where(annee: @annee_a_afficher).to_a
    @avis_par_bop = @avis.group_by(&:bop_id)
  end

  def suivi_remplissage
    @annee_a_afficher = annee_a_afficher
    @controleurs = User.includes(:avis).where(statut: ['CBR', 'DCB'])
    @dcb = User.includes(consulted_bops: :avis).where(statut: 'DCB')
    @avis = Avi.where(annee: @annee_a_afficher)
  end

  def restitutions
    @annee_a_afficher = annee_a_afficher
    @perimetre = params[:perimetre] == 'perimetre' && current_user.statut != 'admin' ? 'perimetre' : 'national'
    if @perimetre == 'perimetre'
      @avis_total = current_user.bops_actifs(@annee_a_afficher).count
      @avis_remplis = current_user.avis_remplis_annee(@annee_a_afficher)
      @programmes = current_user.programmes_access
    else
      @avis_total = bops_actifs(Bop.all, @annee_a_afficher).count
      @avis_remplis = avis_annee_remplis(@annee_a_afficher)
      @programmes = Programme.where(deconcentre: true).includes(bops: :avis).order(numero: :asc)
    end
  end

  private

  def avi_params
    params.require(:avi).permit(:user_id, :phase, :phase_id, :bop_id, :date_reception, :date_envoi, :is_delai, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :commentaire, :etat, :annee, :duree_prevision, :avis_recu, :motif_absence)
  end

  # Force statut/etat et nullifie les champs non pertinents quand avis_recu = false.
  # En "début de gestion", on programme toujours un CRG1 si l'avis n'a pas été reçu.
  # Bascule Non → Oui : reset motif_absence pour ne pas conserver une donnée masquée.
  def force_non_recu_attributes!(attrs)
    avis_recu = attrs[:avis_recu]
    if avis_recu == 'false' || avis_recu == false
      is_crg1_value = attrs[:phase] == 'début de gestion' ? true : nil
      attrs.merge(
        avis_recu: false,
        statut: 'Non reçu',
        etat: 'Lu',
        date_envoi: nil, date_reception: nil,
        is_delai: nil, is_crg1: is_crg1_value,
        ae_i: nil, ae_f: nil, cp_i: nil, cp_f: nil,
        t2_i: nil, t2_f: nil, etpt_i: nil, etpt_f: nil,
        commentaire: nil, duree_prevision: nil
      )
    elsif avis_recu == 'true' || avis_recu == true
      attrs.merge(avis_recu: true, motif_absence: nil)
    else
      attrs
    end
  end

  def set_bop
    @bop = Bop.find(params[:bop_id])
  end

  def set_liste_motifs
    @liste_motifs = Avi::MOTIFS_ABSENCE
  end

  def set_avis_phase(annee)
    avis_annee_courante = @bop.avis.where(annee: annee)
    @avis_debut = avis_annee_courante.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1 = avis_annee_courante.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2 = avis_annee_courante.select { |a| a.phase == 'CRG2' }[0]
    @avis_sv = avis_annee_courante.select { |a| a.phase == 'services votés' && a.etat == 'Brouillon' }[0]
    avis_annee_precedente = @bop.avis.where(annee: annee - 1)
    @avis_debut_n1 = avis_annee_precedente.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG2' }[0]
  end

  # fonction pour afficher le bon formulaire
  def set_form_phase(annee)
    if annee == @annee && @phase_courante == 'services votés'
      'services votés'
    elsif @avis_debut.nil? || @avis_debut.etat == 'Brouillon' || (annee == @annee && Date.today < @date_crg1) # tant que user n'a pas rempli début de gestion ou que la phase CRG1 ne démarre pas
      'début de gestion'
    elsif (@avis_debut.is_crg1 && (@avis_crg1.nil? || @avis_crg1.etat == 'Brouillon')) || (annee == @annee && Date.today < @date_crg2) # avis début de gestion rempli et phase de CRG1
      'CRG1'
    else
      # avis début de gestion rempli et phase de CRG2 sauf si CRG1 présent et non rempli
      'CRG2'
    end
  end

  def redirect_unless_dcb
    redirect_to root_path and return if current_user.statut != 'DCB'
  end

  def redirect_unless_bop_controller
    redirect_to remplissage_avis_path and return if @bop.nil? || @bop.user != current_user
  end

  def dcb_is_updating?
    @bop.user_id == @bop.dcb_id && params[:avi][:etat] != 'Brouillon'
  end

  def count_active_filters(q_params)
    return 0 if q_params.blank?

    count = 0

    # Filtres de type tableau
    count += Array(q_params[:phase_in]).reject(&:blank?).size
    count += Array(q_params[:annee_in]).reject(&:blank?).size
    count += Array(q_params[:etat_in]).reject(&:blank?).size
    count += Array(q_params[:statut_in]).reject(&:blank?).size

    # Filtres de type texte/select
    count += 1 if q_params[:bop_code_cont].present?
    count += 1 if q_params[:user_nom_eq].present?
    count += 1 if q_params[:date_envoi_gteq].present?
    count += 1 if q_params[:date_envoi_lteq].present?

    count
  end

end
