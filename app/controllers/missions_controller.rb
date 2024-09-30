class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_cbr, only: %i[index show]
  def index
    @missions = Mission.all.order(nom: :asc)
  end

  def show
    @mission = Mission.find(params[:id])
    @programmes = @mission.programmes.includes(schemas: :gestion_schemas).where(statut: 'Actif').order(numero: :asc)
    filename = "schemas_mission.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" }
    end
  end
end
