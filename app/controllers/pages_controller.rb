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

  # Page des restitutions nationales
  def restitutions
    @annee_a_afficher = annee_a_afficher
    @avis_total = bops_actifs(Bop.all, @annee).count
    @avis_remplis = avis_annee_remplis(@annee)
    # graphes
    @avis_repartition = avis_repartition(@avis_remplis, @avis_total)
    @avis_date_repartition = avis_date_repartition(@avis_remplis, @avis_total, @annee_a_afficher)
    @notes_bar = statut_bop_repartition(@avis_remplis, @avis_total, @annee_a_afficher)
    # cartes programmes
    variables_restitutions_programmes(@annee_a_afficher)
    @programmes = liste_programmes(@annee_a_afficher)
    @liste_avis_par_programme = @avis_remplis.joins(:bop).group('bops.numero_programme').count
  end

  # Page des restitutions au niveau d'un programme
  def restitution_programme
    redirect_si_programme_non_existant
    @annee_a_afficher = annee_a_afficher
    variables_programme_bops(@annee_a_afficher)
    @avis_remplis = avis_remplis_programme(@annee_a_afficher, @bops)
    # tableau données sommes globales et SD
    array_controleur_id = User.where(statut: 'CBR').pluck(:id)
    avis_remplis_controleur = @avis_remplis.where(user_id: array_controleur_id)
    @hash_donnees_phase = calcul_hash_donnees_phase(@avis_remplis)
    @hash_donnees_phase_controleur = calcul_hash_donnees_phase(avis_remplis_controleur)
    @credit_hash = calcul_credits_phase(@annee_a_afficher)
    # graphes
    @avis_repartition = avis_repartition(@avis_remplis, @bops_actifs_count)
    @avis_date_repartition = avis_date_repartition(@avis_remplis, @bops_actifs_count, @annee_a_afficher)
    @notes_bar = statut_bop_repartition(@avis_remplis, @bops_actifs_count, @annee_a_afficher)
    # filtres liste des BOP
    @bops_user = @bops.joins(:user).pluck(:id, :nom).uniq.to_h
    @bops_user_id = @bops.joins(:user).pluck(:user_id, :nom).uniq.to_h
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # fonction pour filtrer la liste des BOP dans la page de restitution du programme
  def filter_restitution
    @annee_a_afficher = annee_a_afficher
    variables_programme_bops(@annee_a_afficher)
    @avis_remplis = avis_remplis_programme(@annee_a_afficher, @bops)
    # mise à jours de la liste des @bops
    filter_bops_restitution
    @bops_user = @bops.joins(:user).pluck(:id, :nom).to_h
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('liste_bops', partial: 'pages/restitution_liste_bop', locals: { bops: @bops })
        ]
      end
    end
  end



  def mentions_legales; end

  def accessibilite; end

  def donnees_personnelles; end

  def plan; end

  def faq; end

  private


  # fonction pour initialiser les variables de la page restitutions sur l'année sélectionnée
  def variables_restitutions_programmes(annee)
    bops = Bop.where('created_at <= ?', Date.new(annee, 12, 31))
    @total_programmes = bops.distinct.count(:numero_programme)
    @liste_bops_par_programme = bops.group(:numero_programme).count
    liste_bops_inactifs_annee = annee == @annee ? bops.where(dotation: 'aucune') : bops.where.not(id: Avi.where(annee: annee, phase: 'début de gestion').pluck(:bop_id))
    @liste_bops_inactifs_par_programme = liste_bops_inactifs_annee.group(:numero_programme).count
  end

  # fonction pour afficher la liste des programmes (nom et numero) accessibles à l'utilisateur sur l'année
  def liste_programmes(annee)
    id = current_user.id
    scope = current_user.statut == 'admin' ? Bop : Bop.where('user_id = ? OR consultant_id = ?', id, id)
    scope.where('created_at <= ?', Date.new(annee, 12, 31)).order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq.to_h
  end



  # fonction qui initialise les variables de la page restitution du programme en fonction de l'année sélectionnée
  def variables_programme_bops(annee)
    @numero = params[:programme].to_i
    @bops = Bop.where('bops.created_at <= ?', Date.new(annee, 12, 31)).where(numero_programme: @numero).order(code: :asc)
    @bops_count_all = @bops.size
    @bops_actifs_count = annee == @annee ? @bops.count { |b| b.dotation != 'aucune' } : @bops.count { |b| b.avis.where(annee: annee).count.positive? }
    @ministere = @bops.first&.ministere
  end

  # fonction qui redirige vers la page restitutions si le programme n'existe pas
  def redirect_si_programme_non_existant
    tableau_numero_programmes = Bop.all.pluck(:numero_programme).uniq
    redirect_to restitutions_path and return unless tableau_numero_programmes.include?(params[:programme].to_i)
  end

  # fonction qui charge tous les avis des bop d'un programme sur l'année à afficher
  def avis_remplis_programme(annee, bops)
    bops_id = bops.pluck(:id)
    avis_annee = Avi.where(annee: annee, bop_id: bops_id).where.not(etat: 'Brouillon').where.not(phase: 'execution')
    avis_annee_precedente_execution = Avi.where(annee: annee - 1, bop_id: bops_id, phase: 'execution')
    avis_annee.or(avis_annee_precedente_execution)
  end

  # fonction qui initialise les donnees des sommes AE, CP, ETPT par phase
  def init_hash_donnees_phase
    { 'execution' => [0, 0, 0, 0, 0, 0, 0, 0],
      'début de gestion' => [0, 0, 0, 0, 0, 0, 0, 0],
      'CRG1' => [0, 0, 0, 0, 0, 0, 0, 0],
      'CRG2' => [0, 0, 0, 0, 0, 0, 0, 0] }
  end

  # fonction qui calcule les sommes AE, CP,T2, ETPT par phase
  def calcul_hash_donnees_phase(avis_remplis)
    hash_donnees_phase = init_hash_donnees_phase
    avis_debut_gestion_non_crg1 = avis_remplis.select { |avi| avi.phase == 'début de gestion' && !avi.is_crg1 }
    array_somme_debut_non_crg1 = avis_debut_gestion_non_crg1.empty? ? [0, 0, 0, 0, 0, 0, 0, 0] : avis_debut_gestion_non_crg1.pluck(:ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f).transpose.map(&:sum)
    avis_par_phase = avis_remplis.group(:phase).select(:phase, 'SUM(ae_i) AS sum_ae_i', 'SUM(cp_i) AS sum_cp_i', 'SUM(etpt_i) AS sum_etpt_i', 'SUM(t2_i) AS sum_t2_i', 'SUM(ae_f) AS sum_ae_f', 'SUM(cp_f) AS sum_cp_f', 'SUM(etpt_f) AS sum_etpt_f', 'SUM(t2_f) AS sum_t2_f')
    avis_par_phase.each do |avis|
      hash_donnees_phase[avis.phase] = [avis.sum_ae_i, avis.sum_cp_i, avis.sum_t2_i, avis.sum_etpt_i, avis.sum_ae_f, avis.sum_cp_f, avis.sum_t2_f, avis.sum_etpt_f]
    end
    hash_donnees_phase['CRG1'] = hash_donnees_phase['CRG1'].zip(array_somme_debut_non_crg1).map { |x, y| (x || 0) + (y || 0) }
    hash_donnees_phase
  end

  def calcul_credits_phase(annee)
    credit_hash = { 'début de gestion' => [0, 0, 0], 'CRG1' => [0, 0, 0], 'CRG2' => [0, 0, 0]}
    programme_id = Programme.find_by(numero: @numero)&.id
    credits_remplis_programme = Credit.where(annee: annee, programme_id: programme_id)
    credits_remplis_programme.each do |credit|
      credit_hash[credit.phase] = [credit.ae_i, credit.cp_i, credit.t2_i]
    end
    credit_hash
  end

  def filter_bops_restitution
    bops_liste_users = @bops.joins(:user).pluck(:user_id).uniq
    statut = params[:avis]
    users_params = params[:users].map(&:to_i)
    if statut.length != 3 || users_params.length != bops_liste_users.count
      @bops = @bops.where(id: @avis_remplis.select { |a| statut.include?(a.statut) }.pluck(:bop_id)) if statut.length != 3
      @bops = @bops.where(user_id: users_params) if users_params.length != bops_liste_users.count
    end
  end


end
