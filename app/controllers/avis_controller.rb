class AvisController < ApplicationController
	before_action :authenticate_user!	
	
	def index
		@avis = current_user.avis
	end 

	def new
		@bop = Bop.where(id: params[:bop_id]).first
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)

		if @bop.user != current_user
			redirect_to bops_path
		else
			if Date.today <= @date1 
				if @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
				else
					@avis = Avi.new
				end
			elsif @date1 < Date.today && Date.today <= @date2
				if @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
				elsif @bop.avis.where(phase: "CRG1", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG1", etat: "Brouillon").first
				else
					@avis = Avi.new
				end
			elsif Date.today > @date2
				if @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
				elsif @bop.avis.where(phase: "CRG1", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG1", etat: "Brouillon").first
				elsif @bop.avis.where(phase: "CRG2", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG2", etat: "Brouillon").first
				else
					@avis = Avi.new
				end
			end
		end 
	end 

	def create
		@bop = Bop.where(id: params[:bop]).first
		if @bop.user == current_user
			if @bop.avis.where(phase: params[:phase]).count == 0 
				@avis = current_user.avis.new(phase: params[:phase], bop_id: params[:bop], date_reception: params[:date_reception], 
				date_envoi: params[:date_envoi], is_delai: params[:is_delai], is_crg1: params[:is_crg1], statut: params[:statut],
				ae_i: params[:ae_i], cp_i: params[:cp_i], t2_i: params[:t2_i], etpt_i: params[:etpt_i], ae_f: params[:ae_f], cp_f: params[:cp_f],
				t2_f: params[:t2_f], etpt_f: params[:etpt_f], commentaire: params[:commentaire], etat: params[:etat])
				@avis.save
			else
				@avis = @bop.avis.where(phase: params[:phase]).first
				@avis = @avis.update(phase: params[:phase], bop_id: params[:bop], date_reception: params[:date_reception], 
				date_envoi: params[:date_envoi], is_delai: params[:is_delai], is_crg1: params[:is_crg1], statut: params[:statut],
				ae_i: params[:ae_i], cp_i: params[:cp_i], t2_i: params[:t2_i], etpt_i: params[:etpt_i], ae_f: params[:ae_f], cp_f: params[:cp_f],
				t2_f: params[:t2_f], etpt_f: params[:etpt_f], commentaire: params[:commentaire], etat: params[:etat])
			end
			
			if params[:etat] == "Brouillon"
				@message = "Avis sauvegardé en tant que Brouillon"
			else 
				@message = "Avis transmis avec succès"
			end
		end
		respond_to do |format|      
	      format.all { redirect_to historique_path, notice: @message}       
	    end 
	end 

	def update
	end 

	def destroy
		Avi.where(id: params[:id]).destroy_all 
	    respond_to do |format|
	      format.turbo_stream { redirect_to historique_path, notice: "Avis supprimé"  }       
	    end 
	end 

end
