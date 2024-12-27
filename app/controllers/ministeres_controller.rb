class MinisteresController < ApplicationController
  before_action :authenticate_user!
  include ApplicationHelper

  def index
    @ministeres = Ministere.all.order(nom: :asc)
  end

  def show
    @ministere = Ministere.find(params[:id])
    @annee_a_afficher = annee_a_afficher
    @programmes = @ministere.programmes.includes(schemas: :gestion_schemas).where(statut: 'Actif').order(numero: :asc)
    filename = "schemas_ministere.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" }
    end
  end
end
