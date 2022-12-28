class PagesController < ApplicationController
	before_action :authenticate_user!  
  
	def index
		@date1 = Date.new(2023,4,30)
		@date2 = Date.new(2023,8,31)
		@date_alert1 = Date.new(2023,3,15)
		@date_alert2 = Date.new(2023,6,15)
		if Date.today <= @date1
			@phase = "début de gestion"
		elsif @date1 < Date.today && Date.today <= @date2
			@phase = "CRG1"
		elsif Date.today > @date2
			@phase = "CRG2"
		end
		if current_user.statut == "CBR" || current_user.statut == "DCB"
			@avis = current_user.avis
			@avis_total = current_user.bops.count
		else
			@avis = Avi.all
			@avis_total = Bop.all.count
		end
			@avis_valid = @avis.where('phase = ? AND etat != ?',"Début de gestion",'Brouillon')
			@avis_favorables = @avis_valid.select{|a| a.statut == 'Favorable'}.count
			@avis_reserves = @avis_valid.select{|a| a.statut ==  "Favorable avec réserve"}.count
			@avis_defavorables = @avis_valid.select{|a| a.statut == 'Défavorable'}.count
			@avis_vide = @avis_total - @avis_favorables - @avis_reserves - @avis_defavorables
			@avis = [@avis_favorables,@avis_reserves,@avis_defavorables,@avis_vide]
			@avis_crg1 = @avis_valid.select{|a| a.is_crg1 == true}.count
			@avis_delai = @avis_valid.select{|a| a.is_delai == true}.count
			@notes1 = []
			if @date1 < Date.today
				@avis_valid_crg1 = @avis.where('phase = ? AND etat != ?',"CRG1",'Brouillon')
				@notes1_sans_risque = @avis_valid_crg1.select{|a| a.statut == 'Aucun risque'}.count
				@notes1_moyen = @avis_valid_crg1.select{|a| a.statut == "Risques éventuels ou modérés"}.count
				@notes1_risque = @avis_valid_crg1.select{|a| a.statut =='Risques certains ou significatifs'}.count
				@notes1_vide = @avis_crg1 - @notes1_sans_risque - @notes1_moyen - @notes1_risque
				@notes1 = [@notes1_sans_risque,@notes1_moyen,@notes1_risque,@notes1_vide]
			end
			@notes2 = []
			if @date2 < Date.today
				@avis_valid_crg2 = @avis.where('phase = ? AND etat != ?',"CRG2",'Brouillon')
				@notes2_sans_risque = @avis_valid_crg2.select{|a| a.statut =='Aucun risque'}.count
				@notes2_moyen = @avis_valid_crg2.select{|a| a.statut == "Risques éventuels ou modérés"}.count
				@notes2_risque = @avis_valid_crg2.select{|a| a.statut == 'Risques certains ou significatifs'}.count
				@notes2_vide = @avis_total - @notes2_sans_risque - @notes2_moyen - @notes2_risque
				@notes2 = [@notes2_sans_risque,@notes2_moyen,@notes2_risque,@notes2_vide]
			end

	end

	def restitutions
		if current_user.statut == "admin" || current_user.statut == "DCB"
			@programmes = Bop.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
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
		@bops_count = @bops.count
		@ministere = @bops.first.ministere
		@bops_id = @bops.pluck(:id)
		@avis = Avi.where(bop_id: @bops_id, phase: @phase).where("etat != ?","Brouillon")
		@ae_i = @avis.sum(:ae_i)
		@cp_i = @avis.sum(:cp_i)
		@t2_i = @avis.sum(:t2_i)
		@etpt_i = @avis.sum(:etpt_i)
		@ae_f = @avis.sum(:ae_f)
		@cp_f = @avis.sum(:cp_f)
		@t2_f = @avis.sum(:t2_f)
		@etpt_f = @avis.sum(:etpt_f)

		@avis_d = Avi.where(bop_id: @bops_id, phase: "Début de gestion").where.not(etat: "Brouillon")
		@avis_default = @avis_d.first
		@avis_favorables = @avis_d.select{|a| a.statut == 'Favorable'}.length
		@avis_reserves = @avis_d.select{|a| a.statut =="Favorable avec réserve"}.length
		@avis_defavorables = @avis_d.select{|a| a.statut =='Défavorable'}.length
		@avis_vide = @bops_count - @avis_favorables - @avis_reserves - @avis_defavorables
		@avis = [@avis_favorables,@avis_reserves,@avis_defavorables,@avis_vide]
		@avis_iscrg1 = @avis_d.select{|a| a.is_crg1 == true}.length
		@notes1 = []
		if @date1 < Date.today
			@avis_crg1 = Avi.where(bop_id: @bops_id, phase: "CRG1").where.not(etat: "Brouillon")
			@notes1_sans_risque = @avis_crg1.select{|a| a.statut =='Aucun risque'}.length
			@notes1_moyen = @avis_crg1.select{|a| a.statut =="Risques éventuels ou modérés"}.length
			@notes1_risque = @avis_crg1.select{|a| a.statut == 'Risques certains ou significatifs'}.length
			@notes1_vide = @avis_iscrg1 - @notes1_sans_risque - @notes1_moyen - @notes1_risque
			@notes1 = [@notes1_sans_risque,@notes1_moyen,@notes1_risque,@notes1_vide]
		end
		@notes2 = []
		if @date2 < Date.today
			@avis_crg2 = Avi.where(bop_id: @bops_id, phase: "CRG2").where.not(etat: "Brouillon")
			@notes2_sans_risque = @avis_crg2.select{|a| a.statut =='Aucun risque'}.length
			@notes2_moyen = @avis_crg2.select{|a| a.statut =="Risques éventuels ou modérés"}.length
			@notes2_risque = @avis_crg2.select{|a| a.statut == 'Risques certains ou significatifs'}.length
			@notes2_vide = @bops_count - @notes2_sans_risque - @notes2_moyen - @notes2_risque
			@notes2 = [@notes2_sans_risque,@notes2_moyen,@notes2_risque,@notes2_vide]
		end
		@bops_avis_debut_arr = @bops.joins(:avis).where(avis: {phase: "Début de gestion"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
		@bops_avis_debut = Hash[@bops_avis_debut_arr.collect {|a| [a[0],a[1..2]]}]
		@bops_avis_crg1_arr = @bops.joins(:avis).where(avis: {phase: "CRG1"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
		@bops_avis_crg1 = Hash[@bops_avis_crg1_arr.collect {|a| [a[0],a[1..2]]}]
		@bops_avis_crg2_arr = @bops.joins(:avis).where(avis: {phase: "CRG2"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
		@bops_avis_crg2 = Hash[@bops_avis_crg2_arr.collect {|a| [a[0],a[1..2]]}]
		@bops_user = @bops.joins(:user).pluck(:id, :nom).to_h
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
