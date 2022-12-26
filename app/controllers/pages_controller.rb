class PagesController < ApplicationController
	before_action :authenticate_user!  
  
	def index
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		@date_alert1 = Date.new(2023,3,15)
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
		@avis_crg1 = current_user.avis.where("phase = ? AND is_crg1 = ? AND etat != ?", "Début de gestion",  true, "Brouillon").count
		@notes1 = []
		if @date1 < Date.today
			@notes1_sans_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon','Aucun risque').count
			@notes1_moyen = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon',"Risques éventuels ou modérés").count
			@notes1_risque = Avi.where('phase = ? AND etat != ? AND statut = ?', "CRG1",'Brouillon','Risques certains ou significatifs').count
			@notes1_vide = @avis_crg1 - @notes1_sans_risque - @notes1_moyen - @notes1_risque
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

	def restitutions
		if current_user.statut == "admin"
			@programmes = Bop.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
		elsif current_user.statut == "DCB"
			@programmes = Bop.order(numero_programme: :asc).where(consultant: current_user.id).pluck(:numero_programme, :nom_programme).uniq
		elsif current_user.statut == "CBR"
			@programmes = current_user.bops.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
		else
			redirect_to root_path
		end
	end
	def restitution_programme
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		if Date.today <= @date1
			@phase = "début de gestion"
		elsif @date1 < Date.today && Date.today <= @date2
			@phase = "CRG1"
		elsif Date.today > @date2
			@phase = "CRG2"
		end
		@numero = params[:programme]
		@bops = Bop.where(numero_programme: @numero)
		@ministere = Bop.where(numero_programme: @numero).first.ministere
		@bops_id = Bop.where(numero_programme: @numero).pluck(:id)
		@avis = Avi.where(bop_id: @bops_id, phase: @phase).where("etat != ?","Brouillon")
		@ae_i = @avis.sum(:ae_i)
		@cp_i = @avis.sum(:cp_i)
		@t2_i = @avis.sum(:t2_i)
		@etpt_i = @avis.sum(:etpt_i)
		@ae_f = @avis.sum(:ae_f)
		@cp_f = @avis.sum(:cp_f)
		@t2_f = @avis.sum(:t2_f)
		@etpt_f = @avis.sum(:etpt_f)

		@avis_d = Avi.where(bop_id: @bops_id, phase: "Début de gestion").where("etat != ?","Brouillon")
		@avis_favorables = @avis_d.where(statut: 'Favorable').count
		@avis_reserves = @avis_d.where(statut:"Favorable avec réserve").count
		@avis_defavorables = @avis_d.where(statut:'Défavorable').count
		@avis_vide = @bops.count - @avis_favorables - @avis_reserves - @avis_defavorables
		@avis = [@avis_favorables,@avis_reserves,@avis_defavorables,@avis_vide]
		@avis_iscrg1 = @avis_d.where(is_crg1: true).count
		@notes1 = []
		if @date1 < Date.today
			@avis_crg1 = Avi.where(bop_id: @bops_id, phase: "CRG1").where("etat != ?","Brouillon")
			@notes1_sans_risque = @avis_crg1.where(statut: 'Aucun risque').count
			@notes1_moyen = @avis_crg1.where(statut: "Risques éventuels ou modérés").count
			@notes1_risque = @avis_crg1.where(statut: 'Risques certains ou significatifs').count
			@notes1_vide = @avis_iscrg1 - @notes1_sans_risque - @notes1_moyen - @notes1_risque
			@notes1 = [@notes1_sans_risque,@notes1_moyen,@notes1_risque,@notes1_vide]
		end
		@notes2 = []
		if @date2 < Date.today
			@avis_crg2 = Avi.where(bop_id: @bops_id, phase: "CRG2").where("etat != ?","Brouillon")
			@notes2_sans_risque = @avis_crg2.where(statut: 'Aucun risque').count
			@notes2_moyen = @avis_crg2.where(statut: "Risques éventuels ou modérés").count
			@notes2_risque = @avis_crg2.where(statut:'Risques certains ou significatifs').count
			@notes2_vide = @bops.count - @notes2_sans_risque - @notes2_moyen - @notes2_risque
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
