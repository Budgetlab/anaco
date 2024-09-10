# frozen_string_literal: true

# Controller Users
class UsersController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate_admin!, only: [:index, :import, :import_nom, :suivi_remplissage_schemas]
  include ApplicationHelper

  # Page pour ajouter les utilisateurs
  def index
    @users = User.all
  end

  # fonction d'import des utilisateurs dans la bdd par un fichier externe
  def import
    User.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to utilisateurs_path }
    end
  end

  # fonction qui met à jour les noms des utilisateurs dans la bdd grâce au fichier externe importé
  def import_nom
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

  def suivi_remplissage_schemas
    @annee_a_afficher = annee_a_afficher
    users = User.where(statut: 'DCB').includes(:programmes, :schemas).order(nom: :asc)
    @user_data = users.map do |user|
      total_programmes = user.programmes.count
      # ajuster les requêtes schema pour prendre en compte l'année
      schemas_for_year = user.schemas.where(annee: @annee_a_afficher)
      programmes_with_schema = user.programmes_with_schemas(@annee_a_afficher)
      taux = total_programmes.zero? ? 0 : (programmes_with_schema * 100.0) / total_programmes
      {
        nom: user.nom,
        total_programmes: total_programmes,
        programmes_with_schema: programmes_with_schema,
        valide_count: schemas_for_year.where(statut: 'valide').count,
        brouillon_count: schemas_for_year.where.not(statut: 'valide').count,
        taux: taux.round
      }
    end.sort_by { |data| -data[:taux] } # Le signe 'moins' est pour un tri décroissant.
  end
end
