# frozen_string_literal: true

# Controller Users
class UsersController < ApplicationController
  protect_from_forgery with: :null_session

  # Page pour ajouter les utilisateurs
  def index
    redirect_acces_page
  end

  # fonction d'import des utilisateurs dans la bdd par un fichier externe
  def import
    redirect_acces_page
    User.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to utilisateurs_path }
    end
  end

  # fonction qui met à jour les noms des utilisateurs dans la bdd grâce au fichier externe importé
  def import_nom
    redirect_acces_page
    User.import_nom(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to utilisateurs_path }
    end
  end

  # fonction qui renvoie les noms des utilisateurs au moment du choix du profil dans la connexion
  def select_nom
    noms = !params[:statut].nil? ? User.where(statut: params[:statut]).order(nom: :asc).pluck(:nom) : nil
    response = { noms: noms }
    render json: response
  end

  private

  # fonction qui garantit l'accès à la page pour les admin uniquement
  def redirect_acces_page
    redirect_to root_path and return unless current_user && current_user.statut == 'admin'

  end
end
