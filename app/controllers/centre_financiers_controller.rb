class CentreFinanciersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: [:new, :import, :destroy, :export]

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

  def destroy
    @cf = CentreFinancier.find(params[:id])
    if @cf.ht2_actes.empty?
      code = @cf.code
      @cf.destroy
      redirect_to new_centre_financier_path, notice: "CF #{code} supprimé."
    else
      redirect_to new_centre_financier_path, alert: "Impossible de supprimer ce CF : il a des actes associés."
    end
  end

  def export
    @centre_financiers = CentreFinancier.includes(:bop, :programme).order(code: :asc)
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=\"centre_financiers_#{Date.current.strftime('%Y%m%d')}.xlsx\""
      end
    end
  end

  def import
    CentreFinancier.import(params[:file])
    redirect_to new_centre_financier_path
  end
end
