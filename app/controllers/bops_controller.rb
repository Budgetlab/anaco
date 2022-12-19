class BopsController < ApplicationController
	before_action :authenticate_user!	
	protect_from_forgery with: :null_session
	
	def index
		@bops = current_user.bops.order(code: :asc)
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		if Date.today <= @date1
			@phase = "début de gestion"
			@count_reste = current_user.bops.count - current_user.avis.where('phase = ? AND statut != ?', "Début de gestion",'Brouillon').count
		elsif @date1 < Date.today && Date.today <= @date2
			@phase = "CRG1"
			@count_reste_debut = current_user.bops.count - current_user.avis.where('phase = ? AND statut != ?', "Début de gestion",'Brouillon').count
			@count_reste_crg1 = current_user.avis.where('phase = ? AND statut != ? AND is_crg1', "Début de gestion",'Brouillon',true).count - current_user.avis.where('phase = ? AND statut != ?', "CRG1",'Brouillon').count
			@count_reste = @count_reste_debut + @count_reste_crg1
		elsif Date.today > @date2 
			@phase = "CRG2"
			@count_reste_debut = current_user.bops.count - current_user.avis.where('phase = ? AND statut != ?', "Début de gestion",'Brouillon').count
			@count_reste_crg1 = current_user.avis.where('phase = ? AND statut != ? AND is_crg1', "Début de gestion",'Brouillon',true).count - current_user.avis.where('phase = ? AND statut != ?', "CRG1",'Brouillon').count
			@count_reste_crg2 = current_user.avis.where('phase = ? AND statut != ? AND is_crg1', "Début de gestion",'Brouillon',false).count + current_user.avis.where('phase = ? AND statut != ?', "CRG1",'Brouillon').count - current_user.avis.where('phase = ? AND statut != ?', "CRG2",'Brouillon').count
			@count_reste = count_reste_debut + @count_reste_crg1 + @count_reste_crg2
		end 
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
