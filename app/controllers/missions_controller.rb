class MissionsController < ApplicationController
  before_action :authenticate_user!
  def index
    @missions = Mission.all.order(nom: :asc)
  end

  def show
    @mission = Mission.find(params[:id])
    @programmes = @mission.programmes.includes(schemas: :gestion_schemas)
  end
end
