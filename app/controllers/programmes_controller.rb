# frozen_string_literal: true

# controller Programme
class ProgrammesController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:new, :import]
  require 'axlsx'
  include ApplicationHelper
  # Page liste des crédits non repartis par programme
  def index
    @programmes = Programme.all.order(numero: :asc)
    @q = @programmes.ransack(params[:q])
    @programmes = @q.result.includes(:schemas)
    @pagy, @programmes_page = pagy(@programmes)
  end

  def show
    @programme = Programme.find(params[:id])
  end

  # Page pour importer le fichier des programmes
  def new; end

  def import
    Programme.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to new_programme_path }
    end
  end

  def show_last_schema
    @programme = Programme.find(params[:id])
    @schema = @programme.last_schema_valid
    return unless @schema

    @vision_rprog_ht2 = @schema.gestion_schemas.find_by(vision: 'RPROG', profil: 'HT2')
    @vision_rprog_t2 = @schema.gestion_schemas.find_by(vision: 'RPROG', profil: 'T2')
    @vision_cbcm_ht2 = @schema.gestion_schemas.find_by(vision: 'CBCM', profil: 'HT2')
    @vision_cbcm_t2 = @schema.gestion_schemas.find_by(vision: 'CBCM', profil: 'T2')

  end

  def show_avis
    @annee_a_afficher = annee_a_afficher
    @programme = Programme.find(params[:id])
    @bops = @programme.bops.includes(:user).order(code: :asc)
    @avis = Avi.where(bop_id: @bops.pluck(:id), annee: @annee).where.not(etat: 'Brouillon')
  end

end
