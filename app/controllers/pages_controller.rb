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
    # variables
    @statut_user = current_user.statut
    # chargement des avis
    @avis_total = @statut_user == 'admin' ? bops_actifs(Bop.all, @annee).count : current_user.bops_actifs(@annee)
    @avis_remplis = @statut_user == 'admin' ? avis_annee_remplis(@annee) : current_user.avis_remplis_annee(@annee)
    # graphes
    @avis_repartition = avis_repartition(@avis_remplis, @avis_total)
    @notes_crg1 = @date_crg1 <= Date.today ? notes_repartition(@avis_remplis, avis_crg1(@avis_remplis), 'CRG1') : []
    @notes_crg2 = @date_crg2 <= Date.today ? notes_repartition(@avis_remplis, @avis_total, 'CRG2') : []
  end

  def mentions_legales; end

  def accessibilite; end

  def donnees_personnelles; end

  def plan; end

  def faq; end

end
