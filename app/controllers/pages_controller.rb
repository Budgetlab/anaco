class PagesController < ApplicationController
	before_action :authenticate_user!  
  
	def index
	end

	def error_404
	    if params[:path] && params[:path] == "500"
	      render 'error_500'
	    else 
	      render status: 404
	    end 
  	end 

  	def error_500
    	render status: 500
  	end

  	def mentions_legales
  	end 
  
  	def accessibilite
  	end

  	def donnees_personnelles
  	end
end
