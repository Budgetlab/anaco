# frozen_string_literal: true

# Controller Crédits
class CreditsController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  include ApplicationHelper
  # Page historique
  def index
    @annee_a_afficher = annee_a_afficher
    @credits = liste_credits(@annee_a_afficher)
    variables_filtres_table
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  def filter_credits
    @annee_a_afficher = annee_a_afficher
    @credits = liste_credits(@annee_a_afficher)
    variables_filtres_table
    filter_credits_all if params_present_and_credits_not_empty
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('table_index', partial: 'credits/table_index', locals: { credits: @credits }),
          turbo_stream.update('total_table', partial: 'credits/table_total', locals: { total: @credits.length })
        ]
      end
    end
  end

  # Page de création d'un nouveau credit
  def new
    @programme = Programme.where(id: params[:programme_id]).first
    redirect_unless_dcb
    set_credit_phase(@annee)
    @form = set_form_type
    redirect_to programmes_path and return if @form == 'no CRG1'

    @credit = set_form_credit
    @is_completed = @credit&.etat == 'valide'
    if @credit_debut_n1 && (@credit_crg2_n1.nil? || @credit_crg2_n1.etat == 'Brouillon') # n'a pas rempli CRG2 année précédente, on se place sur année N-1
      @annee_a_afficher = @annee - 1
      set_credit_phase(@annee - 1)
    else
      @annee_a_afficher = @annee
    end
    set_variables_form_rappel
  end

  def create
    @programme = Programme.find_by(id: params[:credit][:programme_id])
    redirect_unless_dcb
    @credit = @programme.credits.where(annee: params[:credit][:annee].to_i).find_or_initialize_by(phase: params[:credit][:phase])
    @credit.assign_attributes(credit_params)
    @credit.etat = params[:credit][:etat] == 'Brouillon' ? 'Brouillon' : 'valide'
    @credit.save
    @message = params[:credit][:etat] == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
    respond_to do |format|
      format.html { redirect_to credits_path, notice: @message }
    end
  end

  # fonction qui ouvre les credit nrep et ses infos
  def open_modal_credit
    @credit_default = Credit.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('debut', partial: 'credits/modal_consultation', locals: { credit: @credit_default })
        ]
      end
    end
  end

  # page suivi des crédits remplis par DCB pour DB
  def suivi
    redirect_to root_path and return unless current_user.statut == 'admin'

    @annee_a_afficher = annee_a_afficher
    variables_suivi(@annee_a_afficher)
    @hash_phase_user = calcul_hash_phase_user(@users, @hash_programmes_users, @hash_credits_users, @annee_a_afficher)
  end

  private

  def credit_params
    params.require(:credit).permit(:user_id, :phase, :programme_id, :date_document, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :commentaire, :etat)
  end

  def liste_credits(annee)
    scope = current_user.statut == 'admin' ? Credit : current_user.credits
    credits_all = scope.where(annee: annee).order(created_at: :desc)
    credits_all.joins(:programme, :user).pluck(:id, :phase, :etat, :created_at, :statut, :is_crg1, :ae_i,
                                               :cp_i, :t2_i, :commentaire, :date_document,
                                               'users.nom AS user_nom', 'programmes.id AS programme_id',
                                               'programmes.numero AS programme_numero', 'programmes.nom AS programme_nom')
  end

  def variables_filtres_table
    @users_nom = @credits.map { |el| el[11] }.uniq.sort
    @numeros_programmes = @credits.map { |el| el[13] }.uniq.sort
    puts @numeros_programmes
  end

  def params_present_and_credits_not_empty
    params_present? && !@credits.empty?
  end

  def params_present?
    params[:phases] || params[:statuts] || params[:numeros] || params[:users]
  end

  def filter_credits_all
    @credits = @credits.select { |el| params[:phases].include?(el[1]) } if params[:phases].length != 3
    @credits = @credits.select { |el| params[:statuts].include?(el[4]) } if params[:statuts].length != 3
    @credits = @credits.select { |el| params[:numeros].map(&:to_i).include?(el[13]) } if params[:numeros].length != @numeros_programmes.length
    @credits = @credits.select { |el| params[:users].include?(el[11]) } if params[:users] && params[:users].length != @users_nom.length
  end

  def redirect_unless_dcb
    redirect_to bops_path and return if @programme.nil? || @programme.user != current_user
  end

  def set_credit_phase(annee)
    credit_annee_courante = @programme.credits.where(annee: annee)
    @credit_debut = credit_annee_courante.select { |a| a.phase == 'début de gestion' }[0]
    @credit_crg1 = credit_annee_courante.select { |a| a.phase == 'CRG1' }[0]
    @credit_crg2 = credit_annee_courante.select { |a| a.phase == 'CRG2' }[0]
    credit_annee_precedente = @programme.credits.where(annee: annee - 1)
    @credit_debut_n1 = credit_annee_precedente.select { |a| a.phase == 'début de gestion' }[0]
    @credit_crg1_n1 = credit_annee_precedente.select { |a| a.phase == 'CRG1' }[0]
    @credit_crg2_n1 = credit_annee_precedente.select { |a| a.phase == 'CRG2' }[0]
  end
  # fonction pour afficher le bon formulaire
  def set_form_type
    if @credit_debut_n1 && (@credit_crg2_n1.nil? || @credit_crg2_n1.etat == 'Brouillon') # n'a pas rempli CRG2 année précédente
      'CRG2'
    elsif @credit_debut.nil? || @credit_debut.etat == 'Brouillon' || Date.today < @date_crg1 # tant que user n'a pas rempli début de gestion ou que la phase CRG1 ne démarre pas
      'début de gestion'
    elsif Date.today < @date_crg2 # credit début de gestion rempli et phase de CRG1
      @credit_debut.is_crg1 ? 'CRG1' : 'no CRG1'
    else # credit début de gestion rempli et phase de CRG2 sauf si CRG1 présent et non rempli
      @credit_debut.is_crg1 && (@credit_crg1.nil? || @credit_crg1.etat == 'Brouillon') ? 'CRG1' : 'CRG2'
    end
  end

  # fonction pour donner la bonne valeur de le credit à afficher
  def set_form_credit
    case @form
    when 'début de gestion'
      @credit_debut || Credit.new
    when 'CRG1'
      @credit_crg1 || Credit.new
    when 'CRG2'
      @credit_crg2_n1.nil? || @credit_crg2_n1.etat == 'Brouillon' ? @credit_crg2_n1 || Credit.new : @credit_crg2 || Credit.new
    end
  end

  def set_variables_form_rappel
    @credit_annee_precedente = case @form
                               when 'début de gestion'
                                 @credit_debut_n1
                               when 'CRG1'
                                 @credit_crg1_n1
                               when 'CRG2'
                                 @credit_crg2_n1
                               end
    @credit_phase_precedente = case @form
                              when 'début de gestion'
                                nil
                              when 'CRG1'
                                @credit_debut
                              when 'CRG2'
                                @credit_crg1 ? @credit_crg1 : @credit_debut
                              end
  end

  def variables_suivi(annee)
    @users = User.where(statut: 'DCB')
    @hash_programmes_users = Programme.group(:user_id, :id).count
    @hash_credits_users = Credit.where(annee: annee).group(:user_id, :phase, :statut, :etat, :is_crg1, :programme_id).count

  end
  def calcul_hash_phase_user(users, hash_programmes_users, hash_credits_users, annee)
    hash_phase_user = {}
    ['début de gestion', 'CRG1', 'CRG2'].each do |phase|
      array_suivi_users = []
      users.each do |user|
        array_user = [user.nom,
                      hash_programmes_users.select { |key, value| key[0] == user.id }.values.sum,
                      hash_credits_users.select { |key, value| key.include?(phase) && key[0] == user.id && key.include?('Brouillon') }.values.sum,
                      hash_credits_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && key.include?('Excessive') }.values.sum,
                      hash_credits_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && key.include?('Raisonnable') }.values.sum,
                      hash_credits_users.select { |key, value| key.include?(phase) && key[0] == user.id && !key.include?('Brouillon') && key.include?('Insuffisante') }.values.sum]
        array_user[1] = hash_credits_users.select { |key, value| key.include?('début de gestion') && key[0] == user.id && key.include?(true) && !key.include?('Brouillon')}.values.sum if phase == 'CRG1'
        # array_user[1] = hash_credits_users.select { |key, value| key.include?('début de gestion') && key[0] == user.id }.values.sum if annee < @annee && phase != "CRG1" # total de programmes = avis en début de gestion
        array_user << array_user[1] - (array_user[2] + array_user[3] + array_user[4] + array_user[5]) # notes en attente
        array_user << (array_user[1].zero? ? 100 : (((array_user[3] + array_user[4] + array_user[5]).to_f / array_user[1]) * 100).round)
        array_suivi_users << array_user
      end
      hash_phase_user[phase] = array_suivi_users.sort_by { |e| -e[7] }
    end
    hash_phase_user
  end

end
