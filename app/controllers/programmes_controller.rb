# frozen_string_literal: true

# controller Programme
class ProgrammesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  include ApplicationHelper
  # Page liste des crédits non repartis par programme
  def index
    redirect_to root_path if current_user.statut != 'DCB'

    @annee_a_afficher = annee_a_afficher
    @programmes = current_user.programmes
  end

  # Page pour importer le fichier des programmes
  def new
    redirect_to root_path if current_user.statut != 'admin'
  end

  def import
    Programme.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to new_programme_path }
    end
  end
end
