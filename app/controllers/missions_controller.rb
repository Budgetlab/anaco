class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_cbr, only: %i[index show]
  def index
    @missions = Mission.all.order(nom: :asc)
  end

  def show
    @mission = Mission.find(params[:id])
    @programmes = @mission.programmes.includes(schemas: :gestion_schemas).order(numero: :asc)
  end
end
