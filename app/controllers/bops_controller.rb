# frozen_string_literal: true

# controller des Bop
class BopsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session
  def index
    if current_user.statut == 'admin'
      @liste_bops = Bop.all.order(code: :asc).joins(:user).pluck(:code, :dotation, :numero_programme, :nom_programme, 'users.nom AS user_nom', :id)
      @codes_bop = @liste_bops.map { |el| el[0] }.uniq
      @numeros_programmes = @liste_bops.map { |el| el[2] }.uniq
      @users_nom = @liste_bops.map { |el| el[4] }.uniq
      @dotations = { 'complete' => 'T2/HT2', 'T2' => 'T2', 'HT2' => 'HT2', 'aucune' => 'INACTIF', 'vide' => 'NON RENSEIGNÉ' }
      @dotations_total = [@liste_bops.count { |el| el[1] == 'complete' }, @liste_bops.count { |el| el[1] == 'T2' }, @liste_bops.count { |el| el[1] == 'HT2' }, @liste_bops.count { |el| el[1] == 'aucune' }, @liste_bops.count { |el| el[1] == nil } ]
    else
      @liste_bops = current_user.bops.pluck(:id, :code, :dotation).sort_by { |e| e[1] }
      @liste_bops_actifs = @liste_bops.reject { |el| el[2] == 'aucune' }
      @liste_bops_inactifs = @liste_bops.select { |el| el[2] == 'aucune' }
      @liste_avis_par_bop = current_user.bops.joins(:avis).pluck(:id, 'avis.etat AS avis_etat', 'avis.phase AS avis_phase', 'avis.is_crg1 AS avis_crg1')
      @count_reste = @liste_bops_actifs.length - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' } if @phase == 'début de gestion'
      @count_reste = @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' } if @phase == 'CRG1'
      @count_reste = 2 * @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' } if @phase == 'CRG2'
    end
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  def filter_bop
    @liste_bops = Bop.all.order(code: :asc).joins(:user).pluck(:code, :dotation, :numero_programme, :nom_programme, 'users.nom AS user_nom', :id)
    @codes_bop = @liste_bops.map { |el| el[0] }.uniq
    @numeros_programmes = @liste_bops.map { |el| el[2] }.uniq
    @users_nom = @liste_bops.map { |el| el[4] }.uniq
    if params[:statuts] && params[:statuts].length != 5
      params[:statuts] = params[:statuts].append(nil) if params[:statuts].include?('vide')
      @liste_bops = @liste_bops.select { |b| params[:statuts].include?(b[1]) }
    end
    @liste_bops = @liste_bops.select { |b| params[:numeros].map(&:to_i).include?(b[2]) } if params[:numeros] && params[:numeros].length != @numeros_programmes.length
    @liste_bops = @liste_bops.select { |b| params[:users].include?(b[4]) } if params[:users] && params[:users].length != @users_nom.length
    @liste_bops = @liste_bops.select { |b| params[:bops].include?(b[0]) } if params[:bops] && params[:bops].length != @codes_bop.length
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('table_bops', partial: 'bops/table_bops', locals: { bops: @liste_bops })
        ]
      end
    end
  end

  def show
    @bop = Bop.find(params[:id])
  end

  def edit
    @bop = Bop.find(params[:id])
  end

  def update
    @bop = Bop.find(params[:id])
    @bop.update(dotation: params[:dotation])
    if @bop.dotation == 'aucune'
      # @bop.avis.destroy_all unless @bop.avis.empty?
      @message = 'suppression'
      respond_to do |format|
        format.turbo_stream { redirect_to bops_path, notice: @message }
      end
    else
      respond_to do |format|
        format.turbo_stream { redirect_to new_bop_avi_path(@bop.id) }
      end
    end
  end

  def new
    redirect_to root_path if current_user.statut != 'admin'
  end

  def import
    Bop.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to root_path }
    end
  end
end
