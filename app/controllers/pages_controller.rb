class PagesController < ApplicationController
	before_action :authenticate_user!  
  
	def index
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		if Date.today <= @date1
			@phase = "début de gestion"
		elsif @date1 < Date.today && Date.today <= @date2
			@phase = "CRG1"
		elsif Date.today > @date2
			@phase = "CRG2"
		end
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
