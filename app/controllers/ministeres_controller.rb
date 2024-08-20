class MinisteresController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_cbr, only: %i[index show]

  def index
    @ministeres = Ministere.all.order(nom: :asc)
  end

  def show
    @ministere = Ministere.find(params[:id])
    @programmes = @ministere.programmes.includes(schemas: :gestion_schemas).order(numero: :asc)
  end
end
