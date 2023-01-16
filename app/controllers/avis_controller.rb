class AvisController < ApplicationController
	before_action :authenticate_user!	
	
	def index
		@date1 = Date.new(2022,4,30)
		@date2 = Date.new(2023,8,31)
		if current_user.statut == "admin"
			@avis_all = Avi.order(created_at: :desc)
		else
			@avis_all = current_user.avis.order(created_at: :desc)
		end
		@avis_debut = @avis_all.select { |a| a.phase == "début de gestion" }
		@avis_crg1 = @avis_all.select { |a| a.phase == "CRG1" }
		@avis_crg2 = @avis_all.select { |a| a.phase == "CRG2" }
		@avis_users = @avis_all.joins(:user).pluck(:id,:nom).to_h
		@bops_arr = @avis_all.joins(:bop).pluck(:id,:code, :numero_programme, :nom_programme, :consultant)
		@bops_data = Hash[@bops_arr.collect {|a| [a[0],a[1..4]]}]
		@avis_default = @avis_all.first
		@users = User.pluck(:id,:nom).to_h
	end

	def openModal
		@avis_default = Avi.find(params[:id])
		respond_to do |format|
			format.turbo_stream do
				render turbo_stream: [
					turbo_stream.update('debut', partial: "avis/dialog_debut",locals: {avis: @avis_default}),
				]
			end
		end
	end

	def consultation
		@date1 = Date.new(2022,4,30)
		@date2 = Date.new(2023,8,31)
		@bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id).order(code: :asc)
		@bops_consultation_id = @bops_consultation.pluck(:id)
		@avis_all = Avi.where(bop_id: @bops_consultation_id).where.not(etat: "Brouillon").order(created_at: :desc)
		@avis_debut = @avis_all.select { |a| a.phase == "début de gestion" }
		@bops_vide_debut = @bops_consultation.select { |a| a.id != @avis_debut.pluck(:bop_id) }
		@avis_crg1 = @avis_all.select { |a| a.phase == "CRG1" }
		@bops_vide_crg1 = @bops_consultation.select { |a| a.id != @avis_crg1.pluck(:bop_id) }
		@avis_crg2 = @avis_all.select { |a| a.phase == "CRG2" }
		@bops_vide_crg2 = @bops_consultation.select { |a| a.id != @avis_crg2.pluck(:bop_id) }
		@avis_users = @avis_all.joins(:user).pluck(:id,:nom).to_h
		@bops_arr = @avis_all.joins(:bop).pluck(:id,:code, :numero_programme, :nom_programme)
		@bops_data = Hash[@bops_arr.collect {|a| [a[0],a[1..3]]}]
		@avis_default = @avis_all.first
		@users = User.pluck(:id,:nom).to_h
	end

	def readAvis
		@avis = Avi.find(params[:id])
		@avis.etat = "Lu"
		@avis.save

		@date1 = Date.new(2022,4,30)
		@date2 = Date.new(2023,8,31)
		@bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id).order(code: :asc)
		@bops_consultation_id = @bops_consultation.pluck(:id)
		@avis_all = Avi.where(bop_id: @bops_consultation_id).where.not(etat: "Brouillon").order(created_at: :desc)
		@avis_debut = @avis_all.select { |a| a.phase == "début de gestion" }
		@bops_vide_debut = @bops_consultation.select { |a| a.id != @avis_debut.pluck(:bop_id) }
		@avis_crg1 = @avis_all.select { |a| a.phase == "CRG1" }
		@bops_vide_crg1 = @bops_consultation.select { |a| a.id != @avis_crg1.pluck(:bop_id) }
		@avis_crg2 = @avis_all.select { |a| a.phase == "CRG2" }
		@bops_vide_crg2 = @bops_consultation.select { |a| a.id != @avis_crg2.pluck(:bop_id) }
		@avis_users = @avis_all.joins(:user).pluck(:id,:nom).to_h
		@bops_arr = @avis_all.joins(:bop).pluck(:id,:code, :numero_programme, :nom_programme)
		@bops_data = Hash[@bops_arr.collect {|a| [a[0],a[1..3]]}]
		@avis_default = @avis_all.first
		@users = User.pluck(:id,:nom).to_h

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
		@date1 = Date.new(2022,4,30)
		@date2 = Date.new(2023,8,31)

		@is_completed = false
		if @bop.user != current_user
			redirect_to bops_path
		else
			@avis_debut = @bop.avis.where(phase: "début de gestion").first
			@avis_crg1 = @bop.avis.where(phase: "CRG1").first
			@avis_crg2 = @bop.avis.where(phase: "CRG2").first
			if Date.today <= @date1
				if @avis_debut.nil?
					@avis = Avi.new
				else
					@avis = @avis_debut
					if @avis.etat != "Brouillon"
						@is_completed = true
					end
				end
				@form = "début de gestion"
			elsif @date1 < Date.today && Date.today <= @date2
				@form = "CRG1"
				if @avis_debut.nil?
					@avis = Avi.new
					@form = "début de gestion"
				elsif @avis_debut.etat == "Brouillon"
					@avis = @avis_debut
					@form = "début de gestion"
				elsif @avis_debut.is_crg1 == false
					@form = "no CRG1" #pas de crg1 programmé
				elsif @avis_crg1.nil?
					@avis = Avi.new
				elsif @avis_crg1.etat == "Brouillon"
					@avis = @avis_crg1
				elsif @avis_crg1.etat != "Brouillon"
					@is_completed = true
				end
			elsif Date.today > @date2
				@form = "CRG2"
				if @avis_debut.nil?
					@avis = Avi.new
					@form = "début de gestion"
				elsif @avis_debut.etat == "Brouillon"
					@avis = @avis_debut
					@form = "début de gestion"
				elsif @avis_debut.is_crg1 == true && @avis_crg1.nil?
					@avis = Avi.new
					@form = "CRG1"
				elsif @avis_debut.is_crg1 == true && @avis_crg1.etat == "Brouillon"
					@avis = @avis_crg1
					@form = "CRG1"
				elsif @avis_crg2.nil?
					@avis = Avi.new
				elsif @avis_crg2.etat == "Brouillon"
					@avis = @avis_crg2
				elsif @avis_crg2.etat != "Brouillon"
					@is_completed = true
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
				@message = "Avis sauvegardé en tant que brouillon"
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
