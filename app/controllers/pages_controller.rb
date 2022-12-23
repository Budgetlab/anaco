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
		@avis_favorables = Avi.where('phase = ? AND etat != ? AND statut = ?', "Début de gestion",'Brouillon','Favorable').count
		@avis_reserves = Avi.where('phase = ? AND etat != ? AND statut = ?', "Début de gestion",'Brouillon',"Favorable avec réserve").count
		@avis_defavorables = Avi.where('phase = ? AND etat != ? AND statut = ?', "Début de gestion",'Brouillon','Défavorable').count
		@avis_vide = current_user.bops.count - @avis_favorables - @avis_reserves - @avis_defavorables
		@avis = [@avis_favorables,@avis_reserves,@avis_defavorables,@avis_vide]

		@notes1 = []
		if @date1 < Date.today
			@notes1_sans_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon','Aucun risque').count
			@notes1_moyen = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon',"Risques éventuels ou modérés").count
			@notes1_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon','Risques certains ou significatifs').count
			@notes1_vide = current_user.bops.count - @notes1_sans_risque - @notes1_moyen - @notes1_risque
			@notes1 = [@notes1_sans_risque,@notes1_moyen,@notes1_risque,@notes1_vide]
		end
		@notes2 = []
		if @date2 < Date.today
			@notes2_sans_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG2",'Brouillon','Aucun risque').count
			@notes2_moyen = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG2",'Brouillon',"Risques éventuels ou modérés").count
			@notes2_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG2",'Brouillon','Risques certains ou significatifs').count
			@notes2_vide = current_user.bops.count - @notes2_sans_risque - @notes2_moyen - @notes2_risque
			@notes2 = [@notes2_sans_risque,@notes2_moyen,@notes2_risque,@notes2_vide]
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
