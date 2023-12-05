# frozen_string_literal: true

# controller des Bop
class BopsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session
  # page liste des bops
  def index
    annee_a_afficher
    @liste_bops = liste_bops_user(@annee_a_afficher)
    current_user.statut == 'admin' ? variables_bops_admin : variables_bops_index(@annee_a_afficher)
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  # filtre tableau page liste des bops vision admin
  def filter_bop
    annee_a_afficher
    @liste_bops = liste_bops_user(@annee_a_afficher)
    variables_bops_admin
    filter_bops if params_present
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('table_bops', partial: 'bops/table_bops', locals: { bops: @liste_bops })
        ]
      end
    end
  end

  # page affichage du bop
  def show
    @bop = Bop.find(params[:id])
    @bop_avis = @bop.avis.where.not(phase: 'execution')
  end

  def edit
    @bop = Bop.find(params[:id])
  end

  def update
    @bop = Bop.find(params[:id])
    @bop.update(dotation: params[:dotation])
    if @bop.dotation == 'aucune'
      @message = 'suppression'
      redirect_to bops_path, flash: { notice: @message }
    else
      redirect_to new_bop_avi_path(@bop.id)
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

  private

  def annee_a_afficher
    @annee_a_afficher = params[:date] && [2023, 2024].include?(params[:date].to_i) ? params[:date].to_i : @annee
  end

  def liste_bops_user(annee)
    if current_user.statut == 'admin'
      Bop.where('bops.created_at <= ?', Date.new(annee, 12, 31)).order(code: :asc).joins(:user).pluck(:code, :dotation, :numero_programme, :nom_programme, 'users.nom AS user_nom', :id)
    else
      current_user.bops.where('bops.created_at <= ?', Date.new(annee, 12, 31)).pluck(:id, :code, :dotation).sort_by { |e| e[1] }
    end
  end

  def variables_bops_admin
    @codes_bop = @liste_bops.map { |el| el[0] }.uniq
    @numeros_programmes = @liste_bops.map { |el| el[2] }.uniq
    @users_nom = @liste_bops.map { |el| el[4] }.uniq
    @dotations = { 'complete' => 'T2/HT2', 'T2' => 'T2', 'HT2' => 'HT2', 'aucune' => 'INACTIF', 'vide' => 'NON RENSEIGNÉ' }
    @dotations_total = [@liste_bops.count { |el| el[1] == 'complete' }, @liste_bops.count { |el| el[1] == 'T2' }, @liste_bops.count { |el| el[1] == 'HT2' }, @liste_bops.count { |el| el[1] == 'aucune' }, @liste_bops.count { |el| el[1] == nil } ]
  end

  # variable concernant les BOP sur l'année en cours
  def variables_bops_index(annee)
    @liste_bops_actifs = @liste_bops.reject { |el| el[2] == 'aucune' }
    @liste_bops_inactifs = @liste_bops.select { |el| el[2] == 'aucune' }
    @liste_avis_par_bop = current_user.bops.joins(:avis).where('avis.created_at >= ? AND avis.created_at <= ?', Date.new(annee, 1, 1), Date.new(annee, 12, 31)).pluck(:id, 'avis.etat AS avis_etat', 'avis.phase AS avis_phase', 'avis.is_crg1 AS avis_crg1')
    @count_reste = case @phase
                   when 'début de gestion'
                     @liste_bops_actifs.length - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   when 'CRG1'
                     @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   when 'CRG2'
                     2 * @liste_bops_actifs.length + @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_avis_par_bop.count { |el| el[1] != 'Brouillon' }
                   end
    liste_avis_annee_precedente = current_user.avis.where(created_at: Date.new(annee-1, 1, 1)..Date.new(annee-1, 12, 31))
    liste_avis_annee_precedente_debut = liste_avis_annee_precedente.count { |avis| avis.phase == 'début de gestion' && avis.etat != 'Brouillon' }
    liste_avis_annee_precedente_crg2 = liste_avis_annee_precedente.count { |avis| avis.phase == 'CRG2' && avis.etat != 'Brouillon' }
    @count_reste_annee_precedente = liste_avis_annee_precedente_debut - liste_avis_annee_precedente_crg2
  end

  def filter_bops
    if params[:statuts].length != 5
      params[:statuts] = params[:statuts].append(nil) if params[:statuts].include?('vide')
      @liste_bops = @liste_bops.select { |b| params[:statuts].include?(b[1]) }
    end
    @liste_bops = @liste_bops.select { |b| params[:numeros].map(&:to_i).include?(b[2]) } if params[:numeros].length != @numeros_programmes.length
    @liste_bops = @liste_bops.select { |b| params[:users].include?(b[4]) } if params[:users].length != @users_nom.length
    @liste_bops = @liste_bops.select { |b| params[:bops].include?(b[0]) } if params[:bops].length != @codes_bop.length
  end

  def params_present
    params[:statuts] || params[:numeros] || params[:users] || params[:bops]
  end
end
