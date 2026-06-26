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

  # Page de création d'un nouvel avis.
  # Phase ciblée : params[:phase_id] explicite, sinon next_phase_to_fill (même
  # logique que le bouton "Rédiger" du tableau remplissage_avis).
  # Règle : 1 avis par (BOP, instance de Phase). Si déjà existant :
  #   - brouillon → bascule sur edit pour reprendre la saisie
  #   - finalisé  → retour à la fiche BOP avec un notice
  def new
    @annee_a_afficher = annee_a_afficher
    redirect_to bop_path(@bop) and return unless @bop.actif_en?(@annee_a_afficher)
    redirect_to edit_bop_path(@bop) and return if @bop.dotation.blank?

    avis_bop = @bop.avis.where(annee: @annee_a_afficher).to_a
    @phase_obj = Phase.find_by(id: params[:phase_id]) ||
                 next_phase_to_fill(avis_bop, @annee_a_afficher)
    redirect_to bop_path(@bop), notice: 'Aucun avis à rédiger pour ce BOP.' and return if @phase_obj.nil?

    @phase_form = @phase_obj.nom
    set_avis_phase(@annee_a_afficher)

    existing = @bop.avis.find_by(phase_id: @phase_obj.id, annee: @annee_a_afficher)
    if existing
      if ['Lu', 'En attente de lecture'].include?(existing.etat)
        redirect_to bop_path(@bop), notice: 'Un avis a déjà été transmis pour cette phase.' and return
      end
      redirect_to edit_bop_avi_path(bop_id: @bop.id, id: existing.id) and return
    end

    @avis = @bop.avis.new(phase_id: @phase_obj.id)
  end

  # fonction qui créé un nouvel avis.
  # user_id, phase (string) et annee sont dérivés côté serveur depuis current_user
  # et le phase_id soumis : aucune confiance dans ces 3 valeurs côté client.
  def create
    phase = Phase.find_by(id: avi_params[:phase_id])
    return redirect_to bop_path(@bop), alert: 'Phase invalide.' if phase.nil?

    attrs = avi_params.merge(user_id: current_user.id, phase: phase.nom, annee: phase.annee)
    attrs = force_non_recu_attributes!(attrs, phase_nom: phase.nom)
    attrs = attrs.merge(etat: 'Lu') if dcb_is_updating?
    @avis = @bop.avis.new(attrs)

    if @avis.save
      message = @avis.etat == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
      redirect_to historique_path, notice: message
    else
      setup_form_context_from_avis
      flash.now[:alert] = @avis.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @avis = Avi.find(params[:id])
    @annee_a_afficher = @avis.annee
    @phase_obj  = @avis.phase_periode
    @phase_form = @phase_obj&.nom || @avis.phase
    set_avis_phase(@avis.annee)
  end

  # Update d'un avis existant.
  # Règles :
  #   - avis déjà finalisé (Lu / En attente de lecture) : on préserve l'etat malgré
  #     les modifs (le callback set_etat_avis pourrait sinon le forcer à Brouillon
  #     si un champ obligatoire est vidé).
  #   - DCB qui édite son propre BOP : on bascule etat=Lu (lu automatiquement).
  def update
    @avis = Avi.find(params[:id])
    etat_initial = @avis.etat
    attrs = force_non_recu_attributes!(avi_params, phase_nom: @avis.phase)
    attrs = attrs.merge(etat: etat_initial) if ['Lu', 'En attente de lecture'].include?(etat_initial)
    attrs = attrs.merge(etat: 'Lu') if dcb_is_updating?

    if @avis.update(attrs)
      message = @avis.etat == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
      redirect_to bop_path(@avis.bop), notice: message
    else
      setup_form_context_from_avis
      flash.now[:alert] = @avis.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
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
    avis_all = Avi.where(bop_id: current_user.bops_a_consulter.select(:id))
                  .where.not(etat: 'Brouillon')
                  .order(created_at: :desc)

    # On duplique pour ne pas modifier params directement
    search_params = (params[:q] || {}).dup

    # Par défaut, filtrer sur l'année en cours si aucun filtre n'est spécifié
    if params[:q].blank?
      search_params[:annee_in] = [Date.today.year.to_s]
    end

    # Exposer les params pour l'affichage des filtres dans la vue
    @q_params = search_params.respond_to?(:to_unsafe_h) ? search_params.to_unsafe_h.deep_dup : search_params.deep_dup

    @q = avis_all.ransack(search_params)
    @avis_all = @q.result.includes(:user, bop: :programme)
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

  # Marque un avis (ou tous les avis en attente sur le périmètre du DCB) comme Lu.
  # Sécurité : la lookup est scopée à bops_a_consulter pour qu'un DCB ne puisse pas
  # marquer Lu un avis hors de son périmètre via un id arbitraire.
  def update_etat
    scope = Avi.where(bop_id: current_user.bops_a_consulter.select(:id))
    if params[:id]
      avis = scope.find(params[:id])
      avis.update(etat: 'Lu')
      notice = 'Lu'
    else
      scope.where(etat: 'En attente de lecture').update_all(etat: 'Lu')
      notice = 'Lus'
    end
    redirect_to consultation_path, notice: notice
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
    @annee_a_afficher = @annee
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

  # user_id, phase et annee sont dérivés côté contrôleur (current_user et phase_id),
  # jamais permis depuis le client. bop_id vient de l'URL via @bop.avis.new.
  def avi_params
    params.require(:avi).permit(:phase_id, :date_reception, :date_envoi, :is_delai, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :commentaire, :etat, :duree_prevision, :avis_recu, :motif_absence)
  end

  # Force statut/etat et nullifie les champs non pertinents quand avis_recu = false.
  # En "programmation initiale", on programme toujours un CRG1 si l'avis n'a pas été reçu.
  # Bascule Non → Oui : reset motif_absence pour ne pas conserver une donnée masquée.
  # phase_nom est passé explicitement : le client n'envoie plus :phase dans les params.
  def force_non_recu_attributes!(attrs, phase_nom:)
    avis_recu = attrs[:avis_recu]
    if avis_recu == 'false' || avis_recu == false
      is_crg1_value = phase_nom == 'programmation initiale' ? true : nil
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

  # Recharge les variables d'instance dont la vue new.html.erb a besoin
  # quand on re-render après une erreur de validation sur create.
  # Source canonique de la phase = @avis.phase_periode (objet Phase), peuplé par
  # le callback before_validation depuis phase_id ou (phase, annee).
  def setup_form_context_from_avis
    @annee_a_afficher = @avis.annee || annee_a_afficher
    @phase_obj  = @avis.phase_periode
    @phase_form = @phase_obj&.nom || @avis.phase
    set_avis_phase(@annee_a_afficher)
  end

  def set_avis_phase(annee)
    avis_annee_courante = @bop.avis.where(annee: annee)
    @avis_debut = avis_annee_courante.select { |a| a.phase == 'programmation initiale' }[0]
    @avis_crg1 = avis_annee_courante.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2 = avis_annee_courante.select { |a| a.phase == 'CRG2' }[0]
    avis_annee_precedente = @bop.avis.where(annee: annee - 1)
    @avis_debut_n1 = avis_annee_precedente.select { |a| a.phase == 'programmation initiale' }[0]
    @avis_crg1_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG2' }[0]
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
