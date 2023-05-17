# frozen_string_literal: true

# Controller Pages erreurs
class ErrorsController < ActionController::Base
  def error_500
    render status: 500
  end
  def error_404
    render status: 404
  end
  def error_503
    render status: 503
  end
end