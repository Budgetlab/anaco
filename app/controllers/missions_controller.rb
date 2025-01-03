class MissionsController < ApplicationController
  before_action :authenticate_user!
  include ApplicationHelper
  def index
    @missions = Mission.all.order(nom: :asc)
  end

  def show
    @mission = Mission.find(params[:id])
    @annee_a_afficher = annee_a_afficher
    @programmes = @mission.programmes.includes(schemas: :gestion_schemas).where(statut: 'Actif').order(numero: :asc)
    filename = "schemas_mission.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" }
    end
  end
end
