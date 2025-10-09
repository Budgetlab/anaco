class CentreFinanciersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:new, :import]

  def autocomplete
    query = params[:query].to_s.strip
    puts query

    @centre_financiers = if query.present?
                           CentreFinancier.where("code ILIKE ?", "#{query}%").limit(10).order(code: :asc)
                         else
                           []
                         end

    render json: @centre_financiers.map { |cf| { code: cf.code, id: cf.id } }
  end

  def new
    @centre_financiers_non_valide = CentreFinancier.non_valide
  end

  def import
    CentreFinancier.import(params[:file])
    redirect_to new_centre_financier_path
  end
end
