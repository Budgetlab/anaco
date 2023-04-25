class ApplicationController < ActionController::Base
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
  def set_global_variable
    @date1 = Date.new(2023, 4, 30)
    @date2 = Date.new(2023, 8, 31)
    if Date.today <= @date1
      @phase = "début de gestion"
    elsif @date1 < Date.today && Date.today <= @date2
      @phase = "CRG1"
    elsif Date.today > @date2
      @phase = "CRG2"
    end
  end

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :statut, :nom, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:statut, :password, :nom])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email, :password, :password_confirmation, :statut, :nom ])
  end
end
