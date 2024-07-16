# frozen_string_literal: true

# controller des Avis
class AvisController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_unless_dcb, only: %i[consultation update_etat]
  require 'axlsx'
  include ApplicationHelper
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

  # fonction qui ouvre l'avis et ses infos
  def open_modal
    @avis_default = Avi.find(params[:id])
    if @avis_default.phase == 'début de gestion'
      avis_execution = Avi.where(phase: 'execution', bop_id: @avis_default.bop_id, annee: @avis_default.annee - 1).first
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('debut', partial: 'avis/dialog_debut', locals: { avis: @avis_default, avis_execution: avis_execution || nil })
        ]
      end
    end
  end

  # fonction qui ouvre le modal pour remettre l'avis en brouillon pour la DB
  def open_modal_brouillon
    @avis = Avi.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('modal_brouillon', partial: 'avis/dialog_modifiable', locals: { avis: @avis })
        ]
      end
    end
  end

  # fonction qui remet l'avis en brouillon
  def reset_brouillon
    @avis = Avi.find(params[:id])
    @avis&.update(etat: 'Brouillon')
    if @avis.phase == 'début de gestion'
      @bop = @avis.bop
      @avis_execution = @bop.avis.where(phase: 'execution', annee: @avis.annee - 1).first
      @avis_execution&.update(etat: 'Brouillon')
    end
    respond_to do |format|
      format.turbo_stream { redirect_to bop_path(@avis.bop) }
    end
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
    @avis = Avi.find(params[:id])
    @avis&.update(etat: 'Lu')
    redirect_to consultation_path, flash: { notice: 'Lu' }
  end

  # Page de création d'un nouvel avis
  def new
    @bop = Bop.where(id: params[:bop_id]).first
    redirect_unless_bop_controller
    @annee_a_afficher = annee_a_afficher
    set_avis_phase(@annee_a_afficher)
    @form = set_form_type(@annee_a_afficher)
    @avis = set_form_avis
    @is_completed = ['En attente de lecture', 'Lu'].include?(@avis&.etat)
  end

  # fonction qui créé un nouvel avis
  def create
    @bop = Bop.find_by(id: params[:avi][:bop_id])
    redirect_unless_bop_controller
    @avis = @bop.avis.where(annee: params[:avi][:annee].to_i).find_or_initialize_by(phase: params[:avi][:phase])
    @avis.assign_attributes(avi_params)
    @avis.save
    @message = params[:avi][:etat] == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
    @avis.update(etat: 'Lu') if @bop.user_id == @bop.consultant_id && params[:avi][:etat] != 'Brouillon' && @avis.phase != 'execution' # si DCB lui même
    redirect_path = if @avis.phase == 'execution'
                      @avis.etat == 'valide' ? new_bop_avi_path(@bop.id) : bops_path
                    else
                      historique_path
                    end
    respond_to do |format|
      format.html { redirect_to redirect_path, notice: @message }
    end
  end

  def destroy
    Avi.where(id: params[:id]).destroy_all
    respond_to do |format|
      format.turbo_stream { redirect_to historique_path, notice: 'Avis supprimé' }
    end
  end

  # Page pour importer les avis exécution N-1
  def ajout_avis; end

  def import
    Avi.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to ajout_avis_path }
    end
  end

  private

  def avi_params
    params.require(:avi).permit(:user_id, :phase, :bop_id, :date_reception, :date_envoi, :is_delai, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :commentaire, :etat, :annee)
  end


  def set_avis_phase(annee)
    avis_annee_courante = @bop.avis.where(annee: annee)
    @avis_debut = avis_annee_courante.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1 = avis_annee_courante.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2 = avis_annee_courante.select { |a| a.phase == 'CRG2' }[0]
    avis_annee_precedente = @bop.avis.where(annee: annee - 1)
    @avis_debut_n1 = avis_annee_precedente.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG2' }[0]
    @avis_execution = avis_annee_precedente.select { |a| a.phase == 'execution' }[0]
  end

  # fonction pour afficher le bon formulaire
  def set_form_type(annee)
    if (annee == @annee && @avis_execution.nil? && @avis_debut_n1) || (@avis_execution && @avis_execution.etat != 'valide') # doit remplir le form execution au départ
      'execution'
    elsif @avis_debut.nil? || @avis_debut.etat == 'Brouillon' || (annee == @annee && Date.today < @date_crg1) # tant que user n'a pas rempli début de gestion ou que la phase CRG1 ne démarre pas
      'début de gestion'
    elsif annee == @annee && Date.today < @date_crg2 # avis début de gestion rempli et phase de CRG1
      @avis_debut.is_crg1 ? 'CRG1' : 'no CRG1'
    else # avis début de gestion rempli et phase de CRG2 sauf si CRG1 présent et non rempli
      @avis_debut.is_crg1 && (@avis_crg1.nil? || @avis_crg1.etat == 'Brouillon') ? 'CRG1' : 'CRG2'
    end
  end

  # fonction pour donner la bonne valeur de l'avis à afficher
  def set_form_avis
    case @form
    when 'execution'
      @avis_execution
    when 'début de gestion'
      @avis_debut || Avi.new
    when 'CRG1'
      @avis_crg1 || Avi.new
    when 'CRG2'
      @avis_crg2 || Avi.new
    end
  end

  def redirect_unless_dcb
    redirect_to root_path and return if current_user.statut != 'DCB'
  end

  def redirect_unless_bop_controller
    redirect_to bops_path and return if @bop.nil? || @bop.user != current_user
  end

end
