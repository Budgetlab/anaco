class AvisController < ApplicationController
	before_action :authenticate_user!	
	
	def index
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		if current_user.statut == "admin"
			@avis_debut = Avi.where(phase: "Début de gestion").order(created_at: :desc)
			@avis_crg1 = Avi.where(phase: "CRG1").order(created_at: :desc)
			@avis_crg2 = Avi.where(phase: "CRG2").order(created_at: :desc)
		else
			@avis_debut = current_user.avis.where(phase: "Début de gestion").order(created_at: :desc)
			@avis_crg1 = current_user.avis.where(phase: "CRG1").order(created_at: :desc)
			@avis_crg2 = current_user.avis.where(phase: "CRG2").order(created_at: :desc)
		end
	end

	def consultation
		@bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id).order(code: :asc)
		@bops_consultation_id = @bops_consultation.pluck(:id)
		@avis = Avi.where(bop_id: @bops_consultation_id).where("etat != ?","Brouillon")
		@avis_debut = @avis.where(phase: "Début de gestion").order(created_at: :desc)
		@bops_vide_debut = @bops_consultation.where.not(id: @avis_debut.pluck(:bop_id))
		@avis_crg1 = @avis.where(phase: "CRG1").order(created_at: :desc)
		@bops_vide_crg1 = @bops_consultation.where.not(id: @avis_crg1.pluck(:bop_id))
		@avis_crg2 = @avis.where(phase: "CRG2").order(created_at: :desc)
		@bops_vide_crg2 = @bops_consultation.where.not(id: @avis_crg2.pluck(:bop_id))
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
	end

	def readAvis
		@avis = Avi.find(params[:id])
		@avis.etat = "Lu"
		@avis.save

		@bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id).order(code: :asc)
		@bops_consultation_id = @bops_consultation.pluck(:id)
		@avis = Avi.where(bop_id: @bops_consultation_id).where("etat != ?","Brouillon")
		@avis_debut = @avis.where(phase: "Début de gestion").order(created_at: :desc)
		@bops_vide_debut = @bops_consultation.where.not(id: @avis_debut.pluck(:bop_id))
		@avis_crg1 = @avis.where(phase: "CRG1").order(created_at: :desc)
		@bops_vide_crg1 = @bops_consultation.where.not(id: @avis_crg1.pluck(:bop_id))
		@avis_crg2 = @avis.where(phase: "CRG2").order(created_at: :desc)
		@bops_vide_crg2 = @bops_consultation.where.not(id: @avis_crg2.pluck(:bop_id))
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)

		respond_to do |format|
			format.turbo_stream do
				render turbo_stream: [
					turbo_stream.update('table', partial: "avis/table"),
				]
			end
		end
	end

	def new
		@bop = Bop.where(id: params[:bop_id]).first
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)

		@is_completed = false
		if @bop.user != current_user
			redirect_to bops_path
		else
			if Date.today <= @date1 
				if @bop.avis.where("phase = ? AND etat != ?", "Début de gestion", "Brouillon").count > 0
					@is_completed = true
				elsif @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
				else
					@avis = Avi.new
				end
				@form = "Début de gestion"
			elsif @date1 < Date.today && Date.today <= @date2
				@form = "CRG1"
				if @bop.avis.where(phase: "Début de gestion").count == 0
					@avis = Avi.new
					@form = "Début de gestion"
				elsif @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
					@form = "Début de gestion"
				elsif @bop.avis.where("phase = ? AND etat != ?", "CRG1", "Brouillon").count > 0
					@is_completed = true
				elsif @bop.avis.where(phase: "CRG1", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG1", etat: "Brouillon").first
				elsif @bop.avis.where(phase: "Début de gestion", is_crg1: true).count > 0
					@avis = Avi.new
				else
					@form = "no CRG1" #pas de crg1 programmé
				end
			elsif Date.today > @date2
				@form = "CRG2"
				if @bop.avis.where(phase: "Début de gestion").count == 0
					@avis = Avi.new
					@form = "Début de gestion"
				elsif @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "Début de gestion", etat: "Brouillon").first
					@form = "Début de gestion"
				elsif @bop.avis.where(phase: "CRG1", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG1", etat: "Brouillon").first
					@form = "CRG1"
				elsif @bop.avis.where(phase: "Début de gestion", is_crg1: true).count > 0 && @bop.avis.where(phase: "CRG1").count == 0
					@avis = Avi.new
					@form = "CRG1"
				elsif @bop.avis.where(phase: "CRG2", etat: "Brouillon").count > 0
					@avis = @bop.avis.where(phase: "CRG2", etat: "Brouillon").first
				elsif @bop.avis.where("phase = ? AND etat != ?", "CRG2", "Brouillon").count > 0
					@is_completed = true
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
