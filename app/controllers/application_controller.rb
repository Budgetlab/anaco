# frozen_string_literal: true

# Controller Application

class ApplicationController < ActionController::Base
  include Pagy::Method
  protect_from_forgery with: :exception
  rescue_from ActiveRecord::RecordNotFound do
    flash[:warning] = 'Resource not found.'
     redirect_back_or root_path
  end
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_global_variable
  def redirect_back_or(path)
    redirect_to request.referer || path
  end
  helper_method :resource_name, :resource, :devise_mapping, :resource_class
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def resource_class
    User
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  # Variables globales du calendrier budgétaire de l'année courante.
  #
  # Source de vérité : table `phases`. Les valeurs sont configurables via
  # `/anaco/phases` (admin). Fallback sur les dates par défaut (20/02, 01/06, 01/09)
  # si une phase manque en base — préserve le bon fonctionnement même en cas de
  # données incomplètes.
  #
  # IMPORTANT : la global s'appelle `@phase_courante` (et non `@phase`) pour éviter
  # une collision avec l'ivar resource d'ActiveAdmin pour le modèle `Phase`
  # (`@phase` est utilisé par ResourceController pour mémoïser la Phase trouvée).
  def set_global_variable
    @annee = Date.today.year
    phases_annee = Phase.pour_annee(@annee).to_a

    @date_debut = phases_annee.find { |p| p.nom == 'début de gestion' }&.date_debut || Date.new(@annee, 2, 20)
    @date_crg1  = phases_annee.find { |p| p.nom == 'CRG1' }&.date_debut             || Date.new(@annee, 6, 1)
    @date_crg2  = phases_annee.find { |p| p.nom == 'CRG2' }&.date_debut             || Date.new(@annee, 9, 1)

    # Phase courante : la plus récente dont date_debut est passée.
    # Fallback sur la logique date-pivot si la table ne renvoie rien (cas d'année
    # totalement vide en base ; rare avec les seeds en place).
    @phase_courante = Phase.courante_pour(@annee, Date.today)&.nom
    @phase_courante ||= if Date.today < @date_debut
                          'services votés'
                        elsif Date.today < @date_crg1
                          'début de gestion'
                        elsif Date.today < @date_crg2
                          'CRG1'
                        else
                          'CRG2'
                        end
  end


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :statut, :nom, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:statut, :password, :nom])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :statut, :nom ])
  end

  def authenticate_admin!
    authenticate_user!
    redirect_to root_path unless current_user.statut == 'admin'
  end

  def authenticate_dcb_or_admin!
    authenticate_user!
    redirect_to root_path unless ['admin', 'DCB'].include?(current_user.statut)
  end

  def authenticate_dcb_or_cbr
    authenticate_user!
    redirect_to root_path unless ['CBR', 'DCB'].include?(current_user.statut)
  end

  def redirect_if_cbr
    redirect_to root_path if current_user.statut == 'CBR'
  end

end
