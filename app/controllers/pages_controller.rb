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
    @bops_actifs = @statut_user == 'admin' ? bops_actifs(Bop.all, @annee).count : current_user.bops_actifs(@annee).count
    if @phase_courante == "début de gestion"
      @date_ouverture = @date_debut
      @date_fermeture = @date_crg1.prev_day
    elsif @phase_courante == "CRG1"
      @date_ouverture = @date_crg1
      @date_fermeture = @date_crg2.prev_day
    elsif @phase_courante == "CRG2"
      @date_ouverture = @date_crg2
      @date_fermeture = Date.new(@annee, 12, 31)
    elsif @phase_courante == "services votés"
      @date_ouverture = Date.new(@annee, 1, 1)
      @date_fermeture = @date_debut.prev_day
    end

    @actes = @statut_user == 'admin' ? Acte.all : current_user.actes
    counts = @actes.group(:etat).count
    # Précalculer les valeurs utilisées plusieurs fois dans la vue
    @ht2_echeance_courte = @actes.echeance_courte
    @ht2_long_delay = @actes.count_current_with_long_delay
    @ht2_en_attente_validation = counts["à valider"] || 0
    @ht2_en_attente_validation +=  counts["à suspendre"] || 0
    @ht2_cloture = counts["à clôturer"] || 0
    @ht2_en_cours = counts["en cours d'instruction"] || 0
    @ht2_pre_instruction = counts["en pré-instruction"] || 0
    @ht2_suspendu = counts["suspendu"] || 0
  end

  def mentions_legales; end

  def accessibilite; end

  def donnees_personnelles; end

  def plan; end

  def faq; end

end
