# frozen_string_literal: true

# controller des Avis
class AvisController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  # Page historique des avis
  def index
    annee_a_afficher
    @avis_all = liste_avis_annee(@annee_a_afficher)
    variables_table
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # fonction qui filtre le tableau de la page historique en fonction des paramètres choisis
  def filter_historique
    annee_a_afficher
    @avis_all = liste_avis_annee(@annee_a_afficher)
    variables_table
    filter_avis_all if params_present_and_avis_all_not_empty
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('table_historique', partial: 'avis/table_historique', locals: { liste_avis: @avis_all }),
          turbo_stream.update('total_table', partial: 'avis/table_total', locals: { total: @avis_all.length })
        ]
      end
    end
  end

  # fonction qui ouvre l'avis et ses infos
  def open_modal
    @avis_default = Avi.find(params[:id])
    if @avis_default.phase == 'début de gestion'
      avis_execution = Avi.where(phase: 'execution', bop_id: @avis_default.bop_id, created_at: Date.new(@avis_default.created_at.year,1,1)..Date.new(@avis_default.created_at.year,12,31) ).first
    end
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('debut', partial: 'avis/dialog_debut', locals: { avis: @avis_default, avis_execution: avis_execution || nil })
        ]
      end
    end
  end

  # fonction qui ouvre le modal pour remettre l'avis en brouillon pour la DB
  def open_modal_brouillon
    @avis = Avi.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('modal_brouillon', partial: 'avis/dialog_modifiable', locals: { avis: @avis })
        ]
      end
    end
  end

  # fonction qui remet l'avis en brouillon
  def reset_brouillon
    @avis = Avi.find(params[:id])
    @avis&.update(etat: 'Brouillon')
    respond_to do |format|
      format.turbo_stream { redirect_to bop_path(@avis.bop) }
    end
  end

  # Page de consultation des avis pour les DCB
  def consultation
    redirect_unless_dcb
    annee_a_afficher
    @avis_all = liste_dcb_avis_annee(@annee_a_afficher)
    variables_table
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # fonction qui met à jour l'état de l'avis comme Lu
  def update_etat
    redirect_unless_dcb
    @avis = Avi.find(params[:id])
    @avis&.update(etat: 'Lu')
    annee_a_afficher
    redirect_to consultation_path(date: @annee_a_afficher), flash: { notice: 'Lu' }
  end

  # fonction qui filtre le tableau de la page consultation en fonction des paramètres choisis
  def filter_consultation
    annee_a_afficher
    @avis_all = liste_dcb_avis_annee(@annee_a_afficher)
    variables_table
    filter_avis_all if params_present_and_avis_all_not_empty
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('table', partial: 'avis/table', locals: { liste_avis: @avis_all}),
          turbo_stream.update('total_table', partial: 'avis/table_total', locals: { total: @avis_all.length })
        ]
      end
    end
  end

  # Page de création d'un nouvel avis
  def new
    @bop = Bop.where(id: params[:bop_id]).first
    redirect_unless_bop_controller
    set_avis_phase
    @form = set_form_type
    @avis = set_form_avis
    @is_completed = ['En attente de lecture', 'Lu'].include?(@avis&.etat)
  end

  # fonction qui créé un nouvel avis
  def create
    @bop = Bop.find_by(id: params[:avi][:bop_id])
    redirect_unless_bop_controller
    @avis = @bop.avis.where(created_at: Date.new(@annee, 1, 1)..Date.new(@annee, 12, 31)).find_or_initialize_by(phase: params[:avi][:phase])
    @avis.assign_attributes(avi_params)
    @avis.save
    @message = params[:avi][:etat] == 'Brouillon' ? 'Avis sauvegardé en tant que brouillon' : 'transmis'
    @avis.update(etat: 'Lu') if @bop.user_id == @bop.consultant && params[:avi][:etat] != 'Brouillon' && @avis.phase != 'execution' # si DCB lui même
    respond_to do |format|
      format.html { redirect_to historique_path, notice: @message }
    end
  end

  def destroy
    Avi.where(id: params[:id]).destroy_all
    respond_to do |format|
      format.turbo_stream { redirect_to historique_path, notice: 'Avis supprimé' }
    end
  end

  def ajout_avis; end

  def import
    Avi.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to ajout_avis_path }
    end
  end

  private

  def avi_params
    params.require(:avi).permit(:user_id, :phase, :bop_id, :date_reception, :date_envoi, :is_delai, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :commentaire, :etat)
  end

  def annee_a_afficher
    @annee_a_afficher = params[:date] && [2023, 2024].include?(params[:date].to_i) ? params[:date].to_i : @annee
  end

  def variables_table
    @users_nom = @avis_all.map { |el| el[18] }.uniq.sort
    @codes_bop = @avis_all.map { |el| el[19] }.uniq.sort
    @numeros_programmes = @avis_all.map { |el| el[21] }.uniq.sort
  end

  def params_present_and_avis_all_not_empty
    params_present? && !@avis_all.empty?
  end

  def params_present?
    params[:phases] || params[:statuts] || params[:etats] || params[:numeros] || params[:users] || params[:bops]
  end

  def filter_avis_all
    @avis_all = @avis_all.select { |el| params[:phases].include?(el[1]) } if params[:phases].length != 3
    @avis_all = @avis_all.select { |el| params[:statuts].include?(el[4]) } if params[:statuts].length != 8
    @avis_all = @avis_all.select { |el| params[:etats].include?(el[2]) } if params[:etats].length != 3
    @avis_all = @avis_all.select { |el| params[:numeros].map(&:to_i).include?(el[21]) } if params[:numeros].length != @numeros_programmes.length
    @avis_all = @avis_all.select { |el| params[:users].include?(el[18]) } if params[:users].length != @users_nom.length
    @avis_all = @avis_all.select { |el| params[:bops].include?(el[19])  } if params[:bops].length != @codes_bop.length
  end

  def liste_avis_annee(annee)
    scope = current_user.statut == 'admin' ? Avi : current_user.avis
    avis_all = scope.where('avis.created_at >= ? AND avis.created_at <= ?', Date.new(annee, 1, 1), Date.new(annee, 12, 31)).order(created_at: :desc)
    avis_all.joins(:bop, :user).pluck(:id, :phase, :etat, :created_at, :statut, :is_crg1, :is_delai, :ae_i,
                                       :ae_f, :cp_i, :cp_f, :etpt_i, :etpt_f, :t2_i, :t2_f, :commentaire,
                                       :date_envoi, :date_reception, 'users.nom AS user_nom',
                                       'bops.code AS bop_code', 'bops.id AS bop_id',
                                       'bops.numero_programme AS bop_numero', 'bops.nom_programme AS bop_nom')
  end

  def liste_dcb_avis_annee(annee)
    bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id)
    avis_all = Avi.where(created_at: Date.new(annee, 1, 1)..Date.new(annee, 12, 31), bop_id: bops_consultation.pluck(:id)).where.not(etat: 'Brouillon').order(created_at: :desc)
    avis_all.joins(:bop, :user).pluck(:id, :phase, :etat, :created_at, :statut, :is_crg1, :is_delai, :ae_i,
                                      :ae_f, :cp_i, :cp_f, :etpt_i, :etpt_f, :t2_i, :t2_f, :commentaire,
                                      :date_envoi, :date_reception, 'users.nom AS user_nom',
                                      'bops.code AS bop_code', 'bops.id AS bop_id',
                                      'bops.numero_programme AS bop_numero', 'bops.nom_programme AS bop_nom')
  end

  def set_avis_phase
    avis_annee_courante = @bop.avis.where(created_at: Date.new(@annee, 1, 1)..Date.new(@annee, 12, 31))
    @avis_debut = avis_annee_courante.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1 = avis_annee_courante.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2 = avis_annee_courante.select { |a| a.phase == 'CRG2' }[0]
    @avis_execution = avis_annee_courante.select { |a| a.phase == 'execution' }[0]
    avis_annee_precedente = @bop.avis.where(created_at: Date.new(@annee - 1, 1, 1)..Date.new(@annee - 1, 12, 31))
    @avis_debut_n1 = avis_annee_precedente.select { |a| a.phase == 'début de gestion' }[0]
    @avis_crg1_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG1' }[0]
    @avis_crg2_n1 = avis_annee_precedente.select { |a| a.phase == 'CRG2' }[0]
  end

  # fonction pour afficher le bon formulaire
  def set_form_type
    if @avis_crg2_n1.nil? || @avis_crg2_n1.etat == 'Brouillon' # n'a pas rempli CRG2 année précédente
      'CRG2'
    elsif (@avis_execution.nil? && !@avis_crg2_n1.nil?) || (@avis_execution && @avis_execution.etat != 'valide') # si bop a un avis en crg2 N-1 il doit remplir le form execution sinon direct début de gestion
      'execution'
    elsif @avis_debut.nil? || @avis_debut.etat == 'Brouillon' || Date.today < @date_crg1 # tant que user n'a pas rempli début de gestion ou que la phase CRG1 ne démarre pas
      'début de gestion'
    elsif Date.today < @date_crg2 # avis début de gestion rempli et phase de CRG1
      @avis_debut.is_crg1 ? 'CRG1' : 'no CRG1'
    else # avis début de gestion rempli et phase de CRG2 sauf si CRG1 présent et non rempli
      @avis_debut.is_crg1 && (@avis_crg1.nil? || @avis_crg1.etat == 'Brouillon') ? 'CRG1' : 'CRG2'
    end
  end

  # fonction pour donner la bonne valeur de l'avis à afficher
  def set_form_avis
    case @form
    when 'execution'
      @avis_execution
    when 'début de gestion'
      @avis_debut || Avi.new
    when 'CRG1'
      @avis_crg1 || Avi.new
    when 'CRG2'
      @avis_crg2_n1.nil? || @avis_crg2_n1.etat == 'Brouillon' ? @avis_crg2_n1 || Avi.new : @avis_crg2 || Avi.new
    end
  end

  def redirect_unless_dcb
    redirect_to root_path and return if current_user.statut != 'DCB'
  end

  def redirect_unless_bop_controller
    redirect_to bops_path and return if @bop.nil? || @bop.user != current_user
  end

end
