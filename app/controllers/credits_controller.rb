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

  # Page de création d'un nouvel avis
  def new
    @programme = Programme.where(id: params[:programme_id]).first
  end

  def create
    @programme = Programme.find_by(id: params[:credit][:programme_id])
  end

  private

  def credit_params
    params.require(:credit).permit(:user_id, :phase, :programme_id, :date_document, :is_crg1, :statut, :ae_i, :cp_i, :t2_i, :etpt_i, :commentaire, :etat)
  end

  def liste_credits(annee)
    scope = current_user.statut == 'admin' ? Credit : current_user.credits
    credits_all = scope.where(annee: annee).order(created_at: :desc)
    credits_all.joins(:programme, :user).pluck(:id, :phase, :etat, :created_at, :statut, :is_crg1, :ae_i,
                                               :cp_i, :etpt_i, :t2_i, :commentaire, :date_document,
                                               'users.nom AS user_nom', 'programmes.id AS programme_id',
                                               'programmes.numero AS programme_numero', 'programmes.nom AS programme_nom')
  end

  def variables_filtres_table
    @users_nom = @credits.map { |el| el[12] }.uniq.sort
    @numeros_programmes = @credits.map { |el| el[14] }.uniq.sort
  end

  def params_present_and_credits_not_empty
    params_present? && !@credits.empty?
  end

  def params_present?
    params[:phases] || params[:statuts] || params[:numeros] || params[:users]
  end

  def filter_credits_all
    @credits = @credits.select { |el| params[:phases].include?(el[1]) } if params[:phases].length != 3
    @credits = @credits.select { |el| params[:statuts].include?(el[4]) } if params[:statuts].length != 8
    @credits = @credits.select { |el| params[:numeros].map(&:to_i).include?(el[21]) } if params[:numeros].length != @numeros_programmes.length
    @credits = @credits.select { |el| params[:users].include?(el[18]) } if params[:users] && params[:users].length != @users_nom.length
  end
end
