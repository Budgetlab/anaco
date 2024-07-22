class SchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_programme, only: [:create]
  before_action :retrieve_last_schema_and_redirect_if_incomplete, only: [:create]
  def index
    @schemas = current_user.statut == 'DCB' ? current_user.schemas : Schema.all
    @schemas = @schemas.order(created_at: :desc)
    @q = @schemas.ransack(params[:q])
    @schemas = @q.result.includes(:programme, :user)
    @pagy, @schemas_page = pagy(@schemas)
  end

  def create
    @statut = @programme.dotation == 'T2' ? '3' : '1'
    @schema = @programme.schemas.create(user_id: @programme.user_id, annee: Date.today.year, statut: @statut)

    redirect_to new_schema_gestion_schema_path(@schema)
  end

  # suivi remplissage par programme pour les DCB
  def suivi_remplissage
    @programmes = current_user.programmes.order(numero: :asc)
  end

  private

  def set_programme
    @programme = Programme.find(params[:programme_id])
  end

  def retrieve_last_schema_and_redirect_if_incomplete
    last_schema = @programme.schemas&.where(annee: Date.today.year)&.order(created_at: :desc)&.first
    redirect_to new_schema_gestion_schema_path(@schema) and return if last_schema&.incomplete?
  end
end
