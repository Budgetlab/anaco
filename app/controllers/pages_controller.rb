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
    # Fenêtre d'ouverture de la phase courante, dérivée directement de la table
    # Phase : ouverture = date_debut de la phase, fermeture = veille de la phase
    # suivante (ou 31/12 si elle est la dernière de l'année).
    @date_ouverture = @phase_courante_record.date_debut
    @date_fermeture = @phase_courante_record.date_fermeture

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
