class OrganismesController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:new, :import]

  def autocomplete
    query = params[:query].to_s.strip

    @organismes = if query.present?
                    current_user.organismes.where("nom ILIKE ? OR acronyme ILIKE ?", "%#{query}%", "%#{query}%").limit(10).order(nom: :asc)
                  else
                    []
                  end

    render json: @organismes.map { |org| { nom: org.nom, id: org.id, acronyme: org.acronyme } }
  end

  def index
    @organismes = Organisme.all.order(nom: :asc)
  end

  def new
    @organismes = Organisme.all.order(nom: :asc)
  end

  def import
    if params[:file].present?
      begin
        Organisme.import(params[:file])
        redirect_to new_organisme_path, notice: "Import réussi !"
      rescue => e
        redirect_to new_organisme_path, alert: "Erreur lors de l'import : #{e.message}"
      end
    else
      redirect_to new_organisme_path, alert: "Veuillez sélectionner un fichier"
    end
  end
end
