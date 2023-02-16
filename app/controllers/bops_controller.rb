class BopsController < ApplicationController
	before_action :authenticate_user!	
	protect_from_forgery with: :null_session
	
	def index
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		@avis = current_user.avis

		@bops_inactifs = current_user.bops.where(dotation: "aucune").order(code: :asc)
		@bops_inactifs_count = @bops_inactifs.count
		@bops = current_user.bops.where(dotation: [nil, "complete","T2","HT2"]).order(code: :asc)
		@bops_actifs_count = @bops.count
		if Date.today <= @date1
			@phase = "début de gestion"
			@count_reste = @bops_actifs_count - @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon'}.length
		elsif @date1 < Date.today && Date.today <= @date2
			@phase = "CRG1"
			@count_reste_debut = @bops_actifs_count - @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon'}.length
			@count_reste_crg1 = @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon' && a.is_crg1 == true }.length - @avis.select{ |a| a.phase == "CRG1" && a.etat != 'Brouillon'}.length
			@count_reste = @count_reste_debut + @count_reste_crg1
		elsif Date.today > @date2 
			@phase = "CRG2"
			@count_reste_debut = @bops_actifs_count - @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon'}.length
			@count_reste_crg1 =  @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon' && a.is_crg1 == true }.length - @avis.select{ |a| a.phase == "CRG1" && a.etat != 'Brouillon'}.length
			@count_reste_crg2 = @avis.select{ |a| a.phase == "début de gestion" && a.etat != 'Brouillon' && a.is_crg1 == false }.length + @avis.select{ |a| a.phase == "CRG1" && a.etat != 'Brouillon'}.length - @avis.select{ |a| a.phase == "CRG2" && a.etat != 'Brouillon'}.length
			@count_reste = @count_reste_debut + @count_reste_crg1 + @count_reste_crg2
		end
		@bops_avis_debut = @bops.joins(:avis).where(avis: {phase: "début de gestion"}).pluck(:id, :etat).to_h
		@bops_avis_crg1 = @bops.joins(:avis).where(avis: {phase: "CRG1"}).pluck(:id, :etat).to_h
		@bops_avis_crg2 = @bops.joins(:avis).where(avis: {phase: "CRG2"}).pluck(:id, :etat).to_h
	end 

	def show
		@bop = Bop.find(params[:id])
	end

	def edit
		@bop = Bop.find(params[:id])
	end

	def update
		@bop = Bop.find(params[:id])
		@bop.update(dotation: params[:dotation])
		if @bop.dotation == "aucune"
			if @bop.avis.count > 0
				@bop.avis.destroy_all
			end
			@message = "suppression"
			respond_to do |format|
				format.turbo_stream { redirect_to bops_path, notice: @message  }
			end
		else
			respond_to do |format|
				format.turbo_stream { redirect_to new_bop_avi_path(@bop.id)  }
			end
		end
	end

	def new
		if current_user.statut != "admin"
			redirect_to root_path
		end 
	end 
	def import
		Bop.import(params[:file])
    	respond_to do |format|
		  	format.turbo_stream {redirect_to root_path} 
		end
	end
end
