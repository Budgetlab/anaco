class AvisController < ApplicationController
	before_action :authenticate_user!	
	
	def index
		@avis = current_user.avis
	end 

	def new
		@bop = Bop.where(id: params[:bop_id]).first
	end 

	def create
		@avis = current_user.avis.new(phase: "debut", bop_id: params[:bop], date_reception: params[:date_reception], 
			date_envoi: params[:date_envoi], is_delai: params[:is_delai], is_crg1: params[:is_crg1], statut: params[:statut],
			ae_i: params[:ae_i], cp_i: params[:cp_i], t2_i: params[:t2_i], etpt_i: params[:etpt_i], ae_f: params[:ae_f], cp_f: params[:cp_f],
			t2_f: params[:t2_f], etpt_f: params[:etpt_f], commentaire: params[:commentaire])
		@avis.save
		respond_to do |format|      
	      format.all { redirect_to historique_path, notice: @message}       
	    end 
	end 

	def update
	end 

end
