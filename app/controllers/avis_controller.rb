class AvisController < ApplicationController
	before_action :authenticate_user!	
	
	def index
	end 

	def new
		@bop = Bop.where(id: params[:bop_id]).first
	end 

	def create
	end 

	def update
	end 

end
