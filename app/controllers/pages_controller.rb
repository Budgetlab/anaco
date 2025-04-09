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
    elsif @phase == 'CRG2'
      @notes_crg2 = notes_repartition(@avis_remplis, @avis_total, 'CRG2')
    end

    Ht2Acte.includes(:suspensions).find_each do |acte|
      # Utiliser la méthode existante pour calculer la date_limite
      date_limite_value = acte.calculate_date_limite_value

      # Mettre à jour la colonne date_limite_calculee
      if date_limite_value.present?
        acte.update_column(:date_limite, date_limite_value)
      end
    end


    @ht2_actes = @statut_user == 'admin' ? Ht2Acte.all : current_user.ht2_actes
    counts = @ht2_actes.group(:etat).count
    # Optimisation 4: Précalculer les valeurs utilisées plusieurs fois dans la vue
    @ht2_echeance_courte = @ht2_actes.echeance_courte
    @ht2_long_delay = @ht2_actes.count_current_with_long_delay
    @ht2_en_attente_validation = counts["en attente de validation"] || 0
    @ht2_en_cours = counts["en cours d'instruction"] || 0
    @ht2_pre_instruction = counts["en pré-instruction"] || 0
    @ht2_suspendu = counts["suspendu"] || 0
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
