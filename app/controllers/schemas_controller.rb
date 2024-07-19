class SchemasController < ApplicationController
  before_action :authenticate_user!

  def index
    @schemas = current_user.statut == 'DCB' ? current_user.schemas : Schema.all
    @schemas = @schemas.order(created_at: :desc)
    @q = @schemas.ransack(params[:q])
    @schemas = @q.result.includes(:programme, :user)
    @pagy, @schemas_page = pagy(@schemas)
  end

  # suivi remplissage par programme pour les DCB
  def suivi_remplissage
    @programmes = current_user.programmes.order(numero: :asc)
  end
end
