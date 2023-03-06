class BopsController < ApplicationController
	before_action :authenticate_user!	
	protect_from_forgery with: :null_session
	
	def index
		if current_user.statut == "admin"
			@bops = Bop.all.order(code: :asc)
			@codes_bop = @bops.pluck(:code)
			@numeros_programmes = @bops.pluck(:numero_programme).uniq
			@users = @bops.joins(:user).pluck(:id,:nom).to_h
			@users_id = @bops.joins(:user).pluck(:user_id, :nom).uniq.to_h
			@dotations =  {"complete"=>"T2/HT2","T2"=>"T2","HT2"=>"HT2","aucune"=>"INACTIF", "vide"=>"NON RENSEIGNÉ"}
			@dotations_total = [@bops.select{|b| b.dotation == "complete"}.count,@bops.select{|b| b.dotation == "T2"}.count,@bops.select{|b| b.dotation == "HT2"}.count,@bops.select{|b| b.dotation == "aucune"}.count,@bops.select{|b| b.dotation == nil}.count ]
			@bops.select(:code, :dotation, :numero_programme,:nom_programme, :user_id)
		else

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
		respond_to do |format|
			format.html
			format.xlsx
		end
	end

	def filter_bop
		@bops = Bop.all.order(code: :asc)
		@users = @bops.joins(:user).pluck(:id,:nom).to_h
		@numeros_programmes = @bops.pluck(:numero_programme).uniq
		@codes_bop = @bops.pluck(:code)
		@users_id = @bops.joins(:user).pluck(:user_id, :nom).uniq.to_h
		@bops.select(:code, :dotation, :numero_programme, :nom_programme, :user_id)
		if params[:statuts] && params[:statuts].length != 5
			if params[:statuts].include?("vide")
				params[:statuts] = params[:statuts].append(nil)
			end
			@bops = @bops.select { |b| params[:statuts].include?(b.dotation) }
		end
		if params[:numeros] && params[:numeros].length != @numeros_programmes.length
			@num = params[:numeros].map(&:to_i)
			@bops = @bops.select { |b| @num.include?(b.numero_programme) }
		end
		if params[:users] && params[:users].length != @users_id.length
			@users_s = params[:users].map(&:to_i)
			@bops = @bops.select{ |b| @users_s.include?(b.user_id) }
		end
		if params[:bops] && params[:bops].length != @codes_bop.length
			@bops = @bops.select { |b| params[:bops].include?(b.code) }
		end

		respond_to do |format|
			format.turbo_stream do
				render turbo_stream: [
					turbo_stream.update('table_bops', partial: "bops/table_bops", locals: {bops: @bops, users: @users}),
				]
			end
		end
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
