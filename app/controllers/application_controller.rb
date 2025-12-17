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

  # fonction pour déclarer les variables globales dans l'application
  def set_global_variable
    @annee = Date.today.year
    @date_debut = Date.new(@annee, 2, 12)
    @date_crg1 = Date.new(@annee, 6, 1)
    @date_crg2 = Date.new(@annee, 9, 1)
    if Date.today < @date_debut
      @phase = 'services votés'
    elsif @date_debut <= Date.today && Date.today < @date_crg1
      @phase = 'début de gestion'
    elsif @date_crg1 <= Date.today && Date.today < @date_crg2
      @phase = 'CRG1'
    elsif Date.today >= @date_crg2
      @phase = 'CRG2'
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
