# frozen_string_literal: true

# controller des Avis
class AvisController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:ajout_avis, :import]
  before_action :redirect_unless_dcb, only: %i[consultation update_etat]
  before_action :set_bop, only: %i[new create edit update]
  before_action :redirect_unless_bop_controller, only: %i[new create edit update]
  require 'axlsx'
  include ApplicationHelper
  include AvisHelper
  include BopsHelper
  # Page historique des avis
  def index
    scope = current_user.statut == 'admin' ? Avi : current_user.avis
    avis_all = scope.where.not(phase: 'execution').order(created_at: :desc)
    @q = avis_all.ransack(params[:q])
    @avis_all = @q.result.includes(:bop, :user)
    @pagy, @avis_page = pagy(@avis_all)
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # Page de création d'un nouvel avis
  def new
    @annee_a_afficher = annee_a_afficher
    # Redirection si la dotation du BOP est absente ou vide
    redirect_to edit_bop_path(@bop) and return if @bop.dotation.nil? || @bop.dotation.blank?

    set_avis_phase(@annee_a_afficher) # liste des avis renseignés sur N et N-1 pour les rappels
    # Définir la phase du formulaire et récupérer le dernier avis
    @phase_form = set_form_phase(@annee_a_afficher)
    @last_avis_phase = @bop.avis.where(annee: @annee_a_afficher, phase: @phase_form)&.last
    # Redirection vers edit si le dernier avis est en brouillon
    if @last_avis_phase&.etat == 'Brouillon'
      redirect_to edit_bop_avi_path(bop_id: @bop.id, id: @last_avis_phase.id) and return
    end

    # Définir si le formulaire est complété ou créer un nouvel avis
    if @phase != 'services votés' && ['Lu', 'En attente de lecture'].include?(@last_avis_phase&.etat)
      @is_completed = true
    else
      @avis = @bop.avis.new
    end
  end

  # fonction qui créé un nouvel avis
  def create
    @avis = @bop.avis.new(avi_params)
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
    if ['Lu', 'En attente de lecture'].include?(etat) # avis modifié
      @avis.update(avi_params)
      @avis.etat = etat
      @avis.save
      redirect_to bop_path(@avis.bop), notice: 'Modification'
    elsif @avis.update(avi_params)
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

  # Page de consultation des avis pour les DCB
  def consultation
    bops_consultation = current_user.consulted_bops.where.not(user_id: current_user.id)
    avis_all = Avi.where(bop_id: bops_consultation.pluck(:id)).where.not(etat: 'Brouillon').where.not(phase: 'execution').order(created_at: :desc)
    @q = avis_all.ransack(params[:q])
    @avis_all = @q.result.includes(:bop, :user)
    @pagy, @avis_page = pagy(@avis_all)
    respond_to do |format|
      format.html
      format.xlsx
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

  # Page pour importer les avis exécution N-1
  def ajout_avis; end

  def import
    Avi.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to ajout_avis_path }
    end
  end

  def remplissage_avis
    @annee_a_afficher = annee_a_afficher
    @bops_inactifs = current_user.bops_inactifs(@annee_a_afficher).order(code: :asc)
    @bops_actifs = current_user.bops_actifs(@annee_a_afficher).includes(:avis).order(code: :asc)
    @avis = current_user.avis.where(annee: @annee_a_afficher)
  end

  def suivi_remplissage
    @annee_a_afficher = annee_a_afficher
    @controleurs = User.includes(:avis).where(statut: ['CBR', 'DCB'])
    @dcb = User.includes(consulted_bops: :avis).where(statut: 'DCB')
    @avis = Avi.where(annee: @annee_a_afficher).where.not(phase: 'execution')
  end

  def restitutions
    @annee_a_afficher = annee_a_afficher
    @avis_total = bops_actifs(Bop.all, @annee_a_afficher).count
    @avis_remplis = avis_annee_remplis(@annee_a_afficher)
    @programmes = Programme.where(deconcentre: true).includes(bops: :avis).order(numero: :asc)
  end

  def restitutions_perimetre
    @annee_a_afficher = annee_a_afficher
    @avis_total = current_user.bops_actifs(@annee_a_afficher).count
    @avis_remplis = current_user.avis_remplis_annee(@annee_a_afficher)
    @liste_programmes = current_user.programmes_access
  end

  private

  def avi_params
    params.require(:avi).permit(:user_id, :phase, :bop_id, :date_reception, :date_envoi, :is_delai, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :commentaire, :etat, :annee, :duree_prevision)
  end

  def set_bop
    @bop = Bop.find(params[:bop_id])
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
    @avis_execution = avis_annee_precedente.select { |a| a.phase == 'execution' }[0]
  end

  # fonction pour afficher le bon formulaire
  def set_form_phase(annee)
    # if (annee == @annee && @avis_execution.nil? && @avis_debut_n1) || (@avis_execution && @avis_execution.etat != 'valide') # doit remplir le form execution au départ
    #  'execution'
    if annee == @annee && @phase == 'services votés'
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

end
