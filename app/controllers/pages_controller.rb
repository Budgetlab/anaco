# frozen_string_literal: true

# controller Pages
class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  include ApplicationHelper
  include AvisHelper
  include BopsHelper
  # page d'accueil suivi global des avis par phase selon le profil
  def index
    @statut_user = current_user.statut
    # chargement des avis
    @avis_total = @statut_user == 'admin' ? bops_actifs(Bop.all, @annee).count : current_user.bops_actifs(@annee).count
    @avis_remplis = @statut_user == 'admin' ? avis_annee_remplis(@annee) : current_user.avis_remplis_annee(@annee)
    # graphes
    if @phase == 'début de gestion'
      @avis_repartition = avis_repartition(@avis_remplis, @avis_total, 'début de gestion')
    elsif @phase == 'CRG1'
      @notes_crg1 = notes_repartition(@avis_remplis, avis_crg1(@avis_remplis), 'CRG1')
    elsif @phse == 'CRG2'
      @notes_crg2 = notes_repartition(@avis_remplis, @avis_total, 'CRG2')
    end

    @ht2_actes = @statut_user == 'admin' ? Ht2Acte.all : current_user.ht2_actes
  end

  def global_search
    @statut_user = current_user.statut
    if params[:query].present?
      if @statut_user == 'CBR'
        @bops = current_user.bops.where('code ILIKE ?', "%#{params[:query]}%")
        @programmes = Programme.accessible.where('nom ILIKE ? OR numero ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
        @missions = Mission.where('nom ILIKE ?', "%#{params[:query]}%")
        @ministeres = Ministere.where('nom ILIKE ?', "%#{params[:query]}%")
      else
        @programmes = Programme.accessible.where('nom ILIKE ? OR numero ILIKE ?', "%#{params[:query]}%", "%#{params[:query]}%")
        @missions = Mission.where('nom ILIKE ?', "%#{params[:query]}%")
        @ministeres = Ministere.where('nom ILIKE ?', "%#{params[:query]}%")
        @bops = Bop.where('code ILIKE ?', "%#{params[:query]}%")
      end
    else
      @programmes = []
      @missions = []
      @ministeres = []
      @bops = []
    end
  end

  def mentions_legales; end

  def accessibilite; end

  def donnees_personnelles; end

  def plan; end

  def faq; end

end
