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
    liste_variables_index # chargement dates alerte et user statut
    # notif DCB
    @avis_a_lire = dcb_avis_a_lire
    # chargement des avis
    @avis_total = liste_bop_actifs(@statut_user, @annee)
    @avis_remplis = avis_annee_remplis(@statut_user, @annee)
    # Cartes
    @avis_crg1 = avis_crg1(@avis_remplis)
    @avis_delai = avis_delai(@avis_remplis)
    @credits_nrep = credits_nrep(@statut_user)
    # graphes
    @avis_repartition = avis_repartition(@avis_remplis, @avis_total)
    @notes_crg1 = @date_crg1 <= Date.today ? notes_repartition(@avis_remplis, @avis_crg1, 'CRG1') : []
    @notes_crg2 = @date_crg2 <= Date.today ? notes_repartition(@avis_remplis, @avis_total, 'CRG2') : []
  end

  # Page des restitutions nationales
  def restitutions
    @annee_a_afficher = annee_a_afficher
    @avis_total = liste_bop_actifs('admin', @annee_a_afficher)
    @avis_remplis = avis_annee_remplis('admin', @annee_a_afficher)
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

  # Page suivi remplissage et lecture pour DB
  def suivi
    redirect_to root_path and return unless current_user.statut == 'admin'

    @annee_a_afficher = annee_a_afficher
    variables_suivi(@annee_a_afficher)
    @hash_phase_user = calcul_hash_phase_user(@users, @hash_bops_users, @hash_avis_users, @annee_a_afficher)
    @hash_phase_lecture = calcul_hash_phase_lecture(@users, @hash_bops_users, @hash_avis_users, @annee_a_afficher)
    respond_to do |format|
      format.html
      format.xlsx
    end

  end

  def mentions_legales; end

  def accessibilite; end

  def donnees_personnelles; end

  def plan; end

  def faq; end

  private

  # fonction pour déclarer les variables dans la page index : date alerte fin de gestion, fin CRG1 + statut de l'user
  def liste_variables_index
    @date_alerte_debut_gestion = Date.new(@annee, 3, 15)
    @date_alerte_crg1 = Date.new(@annee, 6, 15)
    @statut_user = current_user.statut
  end

  # fonction pour charger les avis renseignés dans l'année en cours (hors avis d'éxécution et brouillon)
  def avis_annee_remplis(statut_user, annee)
    scope = statut_user == 'admin' ? Avi : current_user.avis
    scope.where(annee: annee).where.not(etat: 'Brouillon').where.not(phase: 'execution')
  end

  # fonction pour récupérer les bops actifs de l'année sélectionnée
  def liste_bop_actifs(statut_user, annee)
    if annee == @annee
      # si année courante prendre ceux actuellement qui n'ont pas aucune comme dotation
      scope = statut_user == 'admin' ? Bop : current_user.bops
      scope.where('bops.created_at <= ?', Date.new(annee, 12, 31)).count { |b| b.dotation != 'aucune' }
    else
      # si année précédente, récupérer ceux qui ont eu des avis pendant cette année en début de gestion (= bop actifs)
      # ceux qui n'ont pas d'avis pendant l'année = bops inactifs
      scope = statut_user == 'admin' ? Avi : current_user.avis
      scope.where(annee: annee, phase: 'début de gestion').count
    end
  end

  # fonction pour charger le nombre des avis à lire par le DCB (ceux des autres CBR/DCB uniquement)
  def dcb_avis_a_lire
    bops_dcb_id = current_user.consulted_bops.where.not(user_id: current_user.id).pluck(:id)
    bops_dcb_id.empty? ? 0 : Avi.where(bop_id: bops_dcb_id, etat: 'En attente de lecture').count
  end

  # fonction pour calculer le nombre d'avis avec CRG1 prévu parmi la liste des avis remplis sur l'année
  def avis_crg1(avis_remplis)
    avis_remplis.count { |a| a.is_crg1 && a.phase == 'début de gestion' }
  end

  # fonction pour calculer le nombre d'avis données sans interruption du delai parmi la liste des avis remplis
  def avis_delai(avis_remplis)
    avis_remplis.count { |a| !a.is_delai && a.phase == 'début de gestion' }
  end



  # fonction pour charger crédits non rep par phase et total
  def credits_nrep(statut_user)
    programmes_count = statut_user == 'admin' ? Programme.all.count : current_user.programmes.count
    credits = statut_user == 'admin' ? Credit : current_user.credits
    credits_debut = programmes_count - credits.count { |credit| credit.phase == 'début de gestion' && credit.etat != 'Brouillon' }
    credits_crg1 = programmes_count - credits.count { |credit| credit.phase == 'CRG1' && credit.etat != 'Brouillon' }
    credits_crg2 = programmes_count - credits.count { |credit| credit.phase == 'CRG2' && credit.etat != 'Brouillon' }
    [programmes_count, credits_debut, credits_crg1, credits_crg2]
  end

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

  def variables_suivi(annee)
    @users = User.where(statut: ['CBR', 'DCB'])
    @hash_bops_users = Bop.where('bops.created_at <= ?', Date.new(annee, 12, 31)).group(:user_id, :dotation, :consultant_id, :id).count
    @hash_avis_users = Avi.where(annee: annee).group(:user_id, :phase, :statut, :etat, :is_crg1, :bop_id).count
  end

  def calcul_hash_phase_user(users, hash_bops_users, hash_avis_users, annee)
    hash_phase_user = {}
    ['début de gestion', 'CRG1', 'CRG2'].each do |phase|
      array_suivi_users = []
      users.each do |user|
        array_user = [user.nom,
                      hash_bops_users.select { |key, value| key[0] == user.id && !key.include?('aucune') }.values.sum,
                      hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && key.include?('Brouillon') }.values.sum,
                      hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Favorable') || key.include?('Aucun risque')) }.values.sum,
                      hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Favorable avec réserve') || key.include?('Risques éventuels ou modérés') || key.include?('Risques modérés')) }.values.sum,
                      hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Défavorable') || key.include?('Risques certains ou significatifs') || key.include?('Risques significatifs')) }.values.sum]
        array_user[1] = hash_avis_users.select { |key, value| key.include?('début de gestion') && key[0] == user.id && key.include?(true) && !key.include?('Brouillon')}.values.sum if phase == 'CRG1'
        array_user[1] = hash_avis_users.select { |key, value| key.include?('début de gestion') && key[0] == user.id }.values.sum if annee < @annee && phase != "CRG1" # total de bop actifs = avis en début de gestion
        array_user << array_user[1] - (array_user[2] + array_user[3] + array_user[4] + array_user[5]) # avis en attente
        array_user << (array_user[1].zero? ? 100 : (((array_user[3] + array_user[4] + array_user[5]).to_f / array_user[1]) * 100).round)
        array_suivi_users << array_user
      end
      hash_phase_user[phase] = array_suivi_users.sort_by { |e| -e[7] }
    end
    hash_phase_user
  end

  def calcul_hash_phase_lecture(users, hash_bops_users, hash_avis_users, annee)
    hash_phase_lecture = {}
    ['début de gestion', 'CRG1', 'CRG2'].each do |phase|
      array_suivi_lecture = []
      users.where(statut: 'DCB').each do |user|
        bop_dcb_id = hash_bops_users.select { |key, value| key[2] == user.id }.keys.map { |element| element[3] }.uniq
        array_user = [user.nom,
                      hash_bops_users.select { |key, value| key[2] == user.id && !key.include?('aucune') }.values.sum,
                      hash_avis_users.select { |key, value| key[1] == phase && bop_dcb_id.include?(key[5]) && key[3] == 'En attente de lecture' }.values.sum,
                      hash_avis_users.select { |key, value| key[1] == phase && bop_dcb_id.include?(key[5]) && key[3] == 'Lu' }.values.sum]
        array_user[1] = hash_avis_users.select { |key, value| key.include?('début de gestion') && bop_dcb_id.include?(key[5]) && key[4] == true && key[3] != 'Brouillon' }.values.sum if phase == 'CRG1'
        array_user[1] = hash_avis_users.select { |key, value| key[1] == 'début de gestion' && bop_dcb_id.include?(key[5]) }.values.sum if annee < @annee && phase != "CRG1"
        array_user << array_user[1] - (array_user[2] + array_user[3])
        array_user << (array_user[2].zero? ? 100 : ((array_user[3].to_f / (array_user[2] + array_user[3])) * 100).round)
        array_suivi_lecture << array_user
      end
      hash_phase_lecture[phase] = array_suivi_lecture.sort_by { |e| -e[5] }
    end
    hash_phase_lecture
  end

end
