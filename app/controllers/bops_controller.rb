# frozen_string_literal: true

# controller des Bop
class BopsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session
  include ApplicationHelper
  # page liste des bops
  def index
    @annee_a_afficher = annee_a_afficher
    @liste_bops = liste_bops_user(@annee_a_afficher)
    if current_user.statut == 'admin'
      @q = @liste_bops.ransack(params[:q])
      @liste_bops = @q.result.includes(:user)
      @pagy, @liste_bops_page = pagy(@liste_bops)
    else
      variables_bops_index(@annee_a_afficher)
    end
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # page affichage du bop
  def show
    @bop = Bop.find(params[:id])
    @bop_avis = @bop.avis.where.not(phase: 'execution')
  end

  # page modification de la dotation du BOP
  def edit
    @bop = Bop.find(params[:id])
  end

  def update
    @bop = Bop.find(params[:id])
    @bop.update(dotation: params[:dotation])
    if @bop.dotation == 'aucune'
      # détruire avis sur l'année en cours (DG) si existe en brouillon
      @bop.avis.where(created_at: Date.new(@annee, 1, 1)..Date.new(@annee, 12, 31), phase: 'début de gestion')&.destroy_all
      @message = 'suppression'
      redirect_to bops_path, flash: { notice: @message }
    else
      redirect_to new_bop_avi_path(@bop.id)
    end
  end

  # page pour importer les BOP dans l'outil
  def new
    redirect_to root_path if current_user.statut != 'admin'
  end

  # fonction pour importer les BOP dans l'outil
  def import
    Bop.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to new_bop_path }
    end
  end

  private

  def liste_bops_user(annee)
    if current_user.statut == 'admin'
      Bop.where('bops.created_at <= ?', Date.new(annee, 12, 31)).order(code: :asc)
    else
      current_user.bops.where('bops.created_at <= ?', Date.new(annee, 12, 31)).pluck(:id, :code, :dotation).sort_by { |e| e[1] }
    end
  end

  # variable concernant les BOP sur l'année en cours pour DBC et CBR
  def variables_bops_index(annee)
    bop_annee_avis_dg_id = current_user.avis.where(annee: annee, phase: 'début de gestion').pluck(:bop_id)
    @liste_bops_actifs = annee == @annee ? @liste_bops.reject { |el| el[2] == 'aucune' } : @liste_bops.select { |el| bop_annee_avis_dg_id.include?(el[0]) }
    @liste_bops_inactifs = annee == @annee ? @liste_bops.select { |el| el[2] == 'aucune' } : @liste_bops.reject { |el| bop_annee_avis_dg_id.include?(el[0]) }
    @liste_avis_par_bop = current_user.bops.joins(:avis).where('avis.annee': annee).where.not('avis.phase': 'execution').pluck(:id, 'avis.etat AS avis_etat', 'avis.phase AS avis_phase', 'avis.is_crg1 AS avis_crg1')
    phase = annee == @annee ? @phase : 'CRG2'
    @count_reste = case phase
                   when 'début de gestion'
                     @liste_bops_actifs.length - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   when 'CRG1'
                     @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   when 'CRG2'
                     puts @liste_bops_actifs.length
                     2 * @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   end
    liste_avis_annee_precedente = current_user.avis.where(annee: annee - 1)
    liste_avis_annee_precedente_debut = liste_avis_annee_precedente.count { |avis| avis.phase == 'début de gestion' && avis.etat != 'Brouillon' }
    liste_avis_annee_precedente_crg2 = liste_avis_annee_precedente.count { |avis| avis.phase == 'CRG2' && avis.etat != 'Brouillon' }
    @count_reste_annee_precedente = liste_avis_annee_precedente_debut - liste_avis_annee_precedente_crg2
  end

end
