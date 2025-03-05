class CentreFinanciersController < ApplicationController
  before_action :authenticate_user!

  def new; end

  def import
    CentreFinancier.import(params[:file])
    redirect_to new_centre_financier_path
  end
end
