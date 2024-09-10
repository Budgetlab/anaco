# frozen_string_literal: true

# controller des Bop
class BopsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:new, :import]
  protect_from_forgery with: :null_session

  def index
    @bops = current_user.statut == 'CBR' ? current_user.bops : Bop.all
    @bops = @bops.order(code: :asc)
    @q = @bops.ransack(params[:q])
    @bops = @q.result.includes(:user)
    @pagy, @bops_page = pagy(@bops)
  end

  # page affichage du bop
  def show
    @bop = Bop.find(params[:id])
    @bop_avis = @bop.avis.where.not(phase: 'execution')
  end

  # page modification de la dotation du BOP
  def edit
    @bop = Bop.find(params[:id])
  end

  def update
    @bop = Bop.find(params[:id])
    @bop.update(dotation: params[:dotation])
    if @bop.dotation == 'aucune'
      # détruire avis sur l'année en cours (DG) si existe en brouillon
      @bop.avis.where(created_at: Date.new(@annee, 1, 1)..Date.new(@annee, 12, 31), phase: 'début de gestion')&.destroy_all
      redirect_to remplissage_avis_path, flash: { notice: 'suppression' }
    else
      redirect_to new_bop_avi_path(@bop.id)
    end
  end

  # page pour importer les BOP dans l'outil (admin)
  def new; end

  # fonction pour importer les BOP dans l'outil  (admin)
  def import
    Bop.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to new_bop_path }
    end
  end
end
