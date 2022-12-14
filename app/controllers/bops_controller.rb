class BopsController < ApplicationController
	before_action :authenticate_user!	
	protect_from_forgery with: :null_session
	
	def index
		@bops = current_user.bops.order(code: :asc)
	end 

	def show
		@bop = Bop.where(id: params[:id]).first
	end

	def new
		if current_user.statut != "admin"
			#redirect_to root_path
		end 
	end 
	def import
		Bop.import(params[:file])
    	respond_to do |format|
		  	format.turbo_stream {redirect_to root_path} 
		end
	end
end
