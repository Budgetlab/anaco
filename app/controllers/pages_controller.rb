# frozen_string_literal: true
# controller Pages
class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  def index
    @date_alert1 = Date.new(2023, 3, 15)
    @date_alert2 = Date.new(2023, 6, 15)
    @avis_remplis = current_user.statut == 'admin' ? Avi.where.not(etat: 'Brouillon') : current_user.avis.where.not(etat: 'Brouillon')
    @avis_total = current_user.statut == 'admin' ? Bop.where(dotation: [nil, 'complete', 'T2', 'HT2']).count : current_user.bops.where(dotation: [nil, 'complete', 'T2', 'HT2']).count
    @bops_consultation = current_user.statut == 'DCB' ? Bop.where(consultant: current_user.id).where.not(user_id: current_user.id) : []
    @avis_to_read = @bops_consultation.empty? ? 0 : Avi.where(bop_id: @bops_consultation.pluck(:id), etat: 'En attente de lecture').count
    @avis_crg1 = @avis_remplis.count { |a| a.is_crg1 && a.phase == 'début de gestion'}
    @avis_delai = @avis_remplis.count { |a| !a.is_delai && a.phase == 'début de gestion'}
    @avis = avisRepartition(@avis_remplis, @avis_total)
    @notes1 = @date1 < Date.today ? notesRepartition(@avis_remplis, @avis_crg1, 'CRG1') : []
    @notes2 = @date2 < Date.today ? notesRepartition(@avis_remplis, @avis_total, 'CRG2') : []
  end

  def restitutions
    @total_programmes = Bop.distinct.count(:numero_programme)
    @programmes = current_user.statut == 'admin' ? Bop.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq.to_h : @programmes = Bop.where('user_id = ? OR consultant = ?', current_user.id, current_user.id).order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq.to_h
    @liste_bops_par_programme = Bop.group(:numero_programme).count
    @liste_bops_inactifs_par_programme = Bop.where(dotation: 'aucune').group(:numero_programme).count
    @avis_total = Bop.where(dotation: [nil, 'complete', 'T2', 'HT2']).count
    @avis_remplis = Avi.where.not(etat: 'Brouillon')
    @avis = avisRepartition(@avis_remplis, @avis_total)
    @avis_date = avisDateRepartition(@avis_remplis, @avis_total)
    @statuts_debut = statutBop(@avis_remplis, @avis_total, 'début de gestion')
    @statuts_crg1 = @date1 < Date.today ? statutBop(@avis_remplis, @avis_total, 'CRG1') : [0, 0, 0, @avis_total]
    @statuts_crg2 = @date2 < Date.today ? statutBop(@avis_remplis, @avis_total, 'CRG2') : [0, 0, 0, @avis_total]
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
    @liste_avis_par_programme = @avis_remplis.joins(:bop).group('bops.numero_programme').count
  end
  def restitution_programme
    @numero = params[:programme]
    @bops = Bop.where(numero_programme: @numero).order(code: :asc)
    @bops_count_all = @bops.size
    @bops_actifs_count = @bops.count { |b| b.dotation != 'aucune'}
    @ministere = @bops.first&.ministere
    @avis_remplis = Avi.where(bop_id: @bops.pluck(:id)).where.not(etat: 'Brouillon')
    @hash_donnees_phase = {'début de gestion' => [0, 0, 0, 0, 0, 0, 0, 0], 'CRG1' => [0, 0, 0, 0, 0, 0, 0, 0], 'CRG2' => [0, 0, 0, 0, 0, 0, 0, 0]}
    avis_par_phase = @avis_remplis.group(:phase).select(:phase, 'SUM(ae_i) AS sum_ae_i', 'SUM(cp_i) AS sum_cp_i', 'SUM(etpt_i) AS sum_etpt_i', 'SUM(t2_i) AS sum_t2_i', 'SUM(ae_f) AS sum_ae_f', 'SUM(cp_f) AS sum_cp_f', 'SUM(etpt_f) AS sum_etpt_f', 'SUM(t2_f) AS sum_t2_f')
    avis_par_phase.each do |avis|
      @hash_donnees_phase[avis.phase] = [avis.sum_ae_i, avis.sum_cp_i, avis.sum_t2_i, avis.sum_etpt_i, avis.sum_ae_f, avis.sum_cp_f, avis.sum_t2_f, avis.sum_etpt_f]
    end
    @avis = avisRepartition(@avis_remplis, @bops_actifs_count)
    @avis_date = avisDateRepartition(@avis_remplis, @bops_actifs_count)
    @statuts_debut = statutBop(@avis_remplis, @bops_actifs_count, 'début de gestion')
    @statuts_crg1 = @date1 < Date.today ? statutBop(@avis_remplis, @bops_actifs_count, 'CRG1') : [0, 0, 0, @bops_actifs_count]
    @statuts_crg2 = @date2 < Date.today ? statutBop(@avis_remplis, @avis_total, 'CRG2') : [0, 0, 0, @bops_actifs_count]
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
    @bops_user = @bops.joins(:user).pluck(:id, :nom).uniq.to_h
    @bops_user_id = @bops.joins(:user).pluck(:user_id, :nom).uniq.to_h
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  def filter_restitution
    @bops = Bop.where(numero_programme: params[:numero].to_i).order(code: :asc)
    bops_liste_users = @bops.joins(:user).pluck(:user_id).uniq
    statut = params[:avis]
    users_params = params[:users].map(&:to_i)
    @avis_remplis = Avi.where(bop_id: @bops.pluck(:id)).where.not(etat: 'Brouillon')
    if statut.length != 3 || users_params.length != bops_liste_users.count
      @bops = @bops.where(id: @avis_remplis.select { |a| statut.include?(a.statut) }.pluck(:bop_id)) if statut.length != 3
      @bops = @bops.where(user_id: users_params) if users_params.length != bops_liste_users.count
    end
    @bops_user = @bops.joins(:user).pluck(:id, :nom).to_h
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('liste_bops', partial: 'pages/restitution_liste_bop')
        ]
      end
    end
  end

  def suivi
    redirect_to root_path and return unless current_user.statut == 'admin'

    @users = User.where(statut: ['CBR', 'DCB'])
    @hash_bops_users = Bop.group(:user_id, :dotation, :consultant, :id).count
    @hash_avis_users = Avi.group(:user_id, :phase, :statut, :etat, :is_crg1, :bop_id).count
    @hash_phase_user = {}
    ['début de gestion', 'CRG1', 'CRG2'].each do |phase|
      array_suivi_users = []
      @users.each do |user|
        array_user = [user.nom,
                       @hash_bops_users.select { |key, value| key[0] == user.id && !key.include?('aucune')}.values.sum,
                       @hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && key.include?('Brouillon')}.values.sum,
                       @hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Favorable') || key.include?('Aucun risque'))}.values.sum,
                       @hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Favorable avec réserve') || key.include?('Risques éventuels ou modérés'))}.values.sum,
                       @hash_avis_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && (key.include?('Défavorable') || key.include?('Risques certains ou significatifs'))}.values.sum]
        array_user[1] = @hash_avis_users.select { |key, value| key.include?('début de gestion') && key[0] == user.id && key.include?(true)}.values.sum if phase == 'CRG1'
        array_user << array_user[1] - (array_user[2] + array_user[3] + array_user[4] + array_user[5])
        array_user << (array_user[1].zero? ? 100 : (((array_user[3] + array_user[4] + array_user[5]).to_f / array_user[1]) * 100).round)
        array_suivi_users << array_user
      end
      @hash_phase_user[phase] = array_suivi_users.sort_by { |e| -e[7] }
    end
    @hash_phase_lecture = {}
    ['début de gestion', 'CRG1', 'CRG2'].each do |phase|
      array_suivi_lecture = []
      @users.where(statut: 'DCB').each do |user|
        bop_to_read = @hash_bops_users.select { |key, value| key[2] == user.id && key[1] != 'aucune' }.keys.map { |element| element[3] }.uniq
        array_user = [user.nom,
                      @hash_bops_users.select { |key, value| key[2] == user.id && !key.include?('aucune')}.values.sum,
                      @hash_avis_users.select { |key, value| key[1] == phase && bop_to_read.include?(key[5]) && key[3] == 'En attente de lecture'}.values.sum,
                      @hash_avis_users.select { |key, value| key[1] == phase && bop_to_read.include?(key[5]) && key[3] == 'Lu'}.values.sum]
        array_user[1] = @hash_avis_users.select { |key, value| key.include?('début de gestion') && bop_to_read.include?(key[5]) && key[4] == true }.values.sum if phase == 'CRG1'
        array_user << array_user[1] - (array_user[2] + array_user[3])
        array_user << (array_user[2].zero? ? 100 : ((array_user[3].to_f / (array_user[2] + array_user[3])) * 100).round)
        array_suivi_lecture << array_user
      end
      @hash_phase_lecture[phase] = array_suivi_lecture.sort_by { |e| -e[5] }
    end
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

  def avisRepartition(avis, avis_total)
    avis_favorables = avis.count { |a| a.statut == 'Favorable' && a.phase == 'début de gestion'}
    avis_reserves = avis.count { |a| a.statut == 'Favorable avec réserve' && a.phase == 'début de gestion' }
    avis_defavorables = avis.count { |a| a.statut == 'Défavorable' && a.phase == 'début de gestion' }
    avis_vide = avis_total - avis_favorables - avis_reserves - avis_defavorables
    @avis = [avis_favorables, avis_reserves, avis_defavorables, avis_vide]
    @avis
  end

  def avisDateRepartition(avis, avis_total)
    avis_date_1 = avis.count { |a| a.date_reception <= Date.new(2023, 3, 1) && a.phase == 'début de gestion'}
    avis_date_2 = avis.count { |a| a.date_reception > Date.new(2023, 3, 1) && a.date_reception <= Date.new(2023, 3, 15) && a.phase == 'début de gestion' }
    avis_date_3 = avis.count { |a| a.date_reception > Date.new(2023, 3, 15) && a.date_reception <= Date.new(2023, 3, 31) && a.phase == 'début de gestion' }
    avis_date_4 = avis.count { |a| a.date_reception > Date.new(2023, 4, 1) && a.phase == 'début de gestion' }
    avis_vide = avis_total - avis_date_1 - avis_date_2 - avis_date_3 - avis_date_4
    @avis_date = [avis_date_1, avis_date_2, avis_date_3, avis_date_4, avis_vide]
    @avis_date
  end

  def notesRepartition(avis, avis_total, phase)
    notes_sans_risque = avis.count { |a| a.statut == 'Aucun risque' && a.phase == phase }
    notes_moyen = avis.count { |a| a.statut == 'Risques éventuels ou modérés' && a.phase == phase }
    notes_risque = avis.count { |a| a.statut == 'Risques certains ou significatifs' && a.phase == phase }
    notes_vide = avis_total - notes_sans_risque - notes_moyen - notes_risque
    @notes = [notes_sans_risque, notes_moyen, notes_risque, notes_vide]
    @notes
  end
  def statutBop(avis, avis_total, phase)
    if phase == 'CRG1'
      @statuts_positive = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? } + avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }
      @statuts_nul = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? } + avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }
      @statuts_negative = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? } + avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }
      @statuts_vide = avis_total - avis.select { |a| a.phase == 'début de gestion' && a.is_crg1 == false }.count - avis.count { |a| a.phase == phase }
    else
      @statuts_positive = avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }
      @statuts_nul = avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }
      @statuts_negative = avis.count { |a| a.phase == phase && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }
      @statuts_vide = avis_total - avis.count { |a| a.phase == phase }
    end
    @statuts = [@statuts_positive, @statuts_nul, @statuts_negative, @statuts_vide]
    return @statuts
  end
end
