class MinisteresController < ApplicationController
  before_action :authenticate_user!

  def index
    @ministeres = Ministere.all.order(nom: :asc)
  end

  def show
    @ministere = Ministere.find(params[:id])
  end
end
