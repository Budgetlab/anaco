class CentreFinanciersController < ApplicationController
  before_action :authenticate_user!

  def autocomplete
    query = params[:query].to_s.strip
    puts query

    @centre_financiers = if query.present?
                           CentreFinancier.where("code LIKE ?", "#{query}%").limit(10).order(code: :asc)
                         else
                           []
                         end

    render json: @centre_financiers.map { |cf| { code: cf.code, id: cf.id } }
  end

  def new
    Programme.all.each do |programme|
      code = "0#{programme.numero}"
      next if CentreFinancier.exists?(code: code)

      cf = CentreFinancier.new
      cf.code = code
      cf.programme_id = programme.id
      cf.save
    end
  end

  def import
    CentreFinancier.import(params[:file])
    redirect_to new_centre_financier_path
  end
end
