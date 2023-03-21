class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  def index
    @date1 = Date.new(2023,4,30)
    @date2 = Date.new(2023,8,31)
    @date_alert1 = Date.new(2023,3,15)
    @date_alert2 = Date.new(2023,6,15)
    @phase = returnPhase(@date1,@date2)
    if current_user.statut == "CBR" || current_user.statut == "DCB"
      @avis_remplis = current_user.avis
      @avis_total = current_user.bops.where(dotation: [nil, "complete","T2","HT2"]).count
      if current_user.statut == "DCB"
        @bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id)
        @bops_consultation_id = @bops_consultation.pluck(:id)
        @avis_to_read = Avi.where(bop_id: @bops_consultation_id).where(etat: "En attente de lecture").count
      end
    else
      @avis_remplis = Avi.all
      @avis_total = Bop.where(dotation: [nil, "complete","T2","HT2"]).count
    end
    @avis_valid = @avis_remplis.where('phase = ? AND etat != ?',"début de gestion",'Brouillon')
    @avis_vide = @avis_total - @avis_valid.count
    @avis = avisRepartition(@avis_valid,@avis_vide)
    @avis_crg1 = @avis_valid.select{|a| a.is_crg1 == true}.count
    @avis_delai = @avis_valid.select{|a| a.is_delai == false}.count
    @notes1 = []
    if @date1 < Date.today
      @avis_valid_crg1 = @avis_remplis.where('phase = ? AND etat != ?',"CRG1",'Brouillon')
      @notes1 = notesRepartition(@avis_valid_crg1, @avis_crg1)
    end
    @notes2 = []
    if @date2 < Date.today
      @avis_valid_crg2 = @avis_remplis.where('phase = ? AND etat != ?',"CRG2",'Brouillon')
      @notes2 = notesRepartition(@avis_valid_crg2, @avis_total)
    end
  end

  def restitutions
    @date1 = Date.new(2023,4,30)
    @date2 = Date.new(2023,8,31)
    @total_programmes = Bop.pluck(:numero_programme).uniq.length
    if current_user.statut == "admin"
      @programmes = Bop.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    elsif	current_user.statut == "DCB"
      @programmes = Bop.where("user_id = ? OR consultant = ?",current_user.id, current_user.id).order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    elsif current_user.statut == "CBR"
      @programmes = current_user.bops.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    else
      redirect_to root_path
    end
    @bops_count = Bop.where(dotation: [nil, "complete","T2","HT2"]).count
    @avis_d = Avi.where(phase: "début de gestion").where.not(etat: "Brouillon")
    @avis_vide = @bops_count - @avis_d.count
    @avis = avisRepartition(@avis_d,@avis_vide)
    @avis_date = avisDateRepartition(@avis_d,@avis_vide)
    @avis_iscrg1 = @avis_d.select{|a| a.is_crg1 == true}.length
    @statuts_debut = [@avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_d.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_d.count ]
    @statuts_crg1 = [0,0,0,@bops_count]
    if @date1 < Date.today
      @avis_crg1 = Avi.where(phase: "CRG1").where.not(etat: "Brouillon")
      @statuts_positive = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count
      @statuts_nul = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count
      @statuts_negative = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count
      @statuts_vide = @bops_count - @avis_d.select { |a| a.is_crg1 == false}.count - @avis_crg1.count
      @statuts_crg1 = [@statuts_positive, @statuts_nul, @statuts_negative, @statuts_vide]
    end
    @statuts_crg2 = [0,0,0,@bops_count]
    if @date2 < Date.today
      @avis_crg2 = Avi.where(phase: "CRG2").where.not(etat: "Brouillon")
      @statuts_crg2 = [@avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_crg2.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_crg2.count ]
    end
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
  end
  def restitution_programme
    @date1 = Date.new(2023,4,30)
    @date2 = Date.new(2023,8,31)
    @phase = returnPhase(@date1,@date2)
    @numero = params[:programme]
    @bops = Bop.where(numero_programme: @numero).order(code: :asc)
    @bops_actifs = @bops.where(dotation: [nil, "complete","T2","HT2"])
    @bops_id_all = @bops.pluck(:id)
    @bops_count_all = @bops_id_all.length
    @bops_id = @bops_actifs.pluck(:id)
    @bops_count = @bops_id.length
    @ministere = @bops.first.ministere

    @avis = Avi.where(bop_id: @bops_id, phase: @phase).where("etat != ?","Brouillon")
    @array = @avis.pluck(:ae_i, :cp_i, :t2_i, :etpt_i,:ae_f, :cp_f, :t2_f, :etpt_f )
    #@data = @array.transpose.map(&:sum)
    @data = [@array.sum { |a,b,c,d,e,f,g,h| a}, @array.sum { |a,b,c,d,e,f,g,h| b},@array.sum { |a,b,c,d,e,f,g,h| c},@array.sum { |a,b,c,d,e,f,g,h| d},@array.sum { |a,b,c,d,e,f,g,h| e}, @array.sum { |a,b,c,d,e,f,g,h| f}, @array.sum { |a,b,c,d,e,f,g,h| g},@array.sum { |a,b,c,d,e,f,g,h| h}]

    @avis_d = Avi.where(bop_id: @bops_id, phase: "début de gestion").where.not(etat: "Brouillon")
    @statuts_debut = [@avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_d.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_d.count ]
    @array_d = @avis_d.pluck(:ae_i, :cp_i, :t2_i, :etpt_i,:ae_f, :cp_f, :t2_f, :etpt_f )
    #@data_d = @array_d.transpose.map(&:sum)
    @data_d = [@array_d.sum { |a,b,c,d,e,f,g,h| a}, @array_d.sum { |a,b,c,d,e,f,g,h| b},@array_d.sum { |a,b,c,d,e,f,g,h| c},@array_d.sum { |a,b,c,d,e,f,g,h| d},@array_d.sum { |a,b,c,d,e,f,g,h| e}, @array_d.sum { |a,b,c,d,e,f,g,h| f}, @array_d.sum { |a,b,c,d,e,f,g,h| g},@array_d.sum { |a,b,c,d,e,f,g,h| h}]
    @avis_default = @avis_d.first
    @avis_vide = @bops_count - @avis_d.count
    @avis = avisRepartition(@avis_d,@avis_vide)
    @avis_date = avisDateRepartition(@avis_d,@avis_vide)
    @avis_iscrg1 = @avis_d.select{|a| a.is_crg1 == true}.length
    @statuts_crg1 = [0,0,0,@bops_count]
    @avis_crg1 = []
    @avis_crg2 = []
    if @date1 < Date.today
      @avis_crg1 = Avi.where(bop_id: @bops_id, phase: "CRG1").where.not(etat: "Brouillon")
      @statuts_positive = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count
      @statuts_nul = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count
      @statuts_negative = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count
      @statuts_vide = @bops_count - @avis_d.select { |a| a.is_crg1 == false}.count - @avis_crg1.count
      @statuts_crg1 = [@statuts_positive, @statuts_nul, @statuts_negative, @statuts_vide]
    end
    @statuts_crg2 = [0,0,0,@bops_count]
    if @date2 < Date.today
      @avis_crg2 = Avi.where(bop_id: @bops_id, phase: "CRG2").where.not(etat: "Brouillon")
      @statuts_crg2 = [@avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_crg2.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_crg2.count ]
      @array_c = @avis_crg1.pluck(:ae_i, :cp_i, :t2_i, :etpt_i,:ae_f, :cp_f, :t2_f, :etpt_f )
      #@data_c = @array_c.transpose.map(&:sum)
      @data_c = [@array_c.sum { |a,b,c,d,e,f,g,h| a}, @array_c.sum { |a,b,c,d,e,f,g,h| b},@array_c.sum { |a,b,c,d,e,f,g,h| c},@array_c.sum { |a,b,c,d,e,f,g,h| d},@array_c.sum { |a,b,c,d,e,f,g,h| e}, @array_c.sum { |a,b,c,d,e,f,g,h| f}, @array_c.sum { |a,b,c,d,e,f,g,h| g},@array_c.sum { |a,b,c,d,e,f,g,h| h}]
    end
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
    @bops_avis_debut_arr = @bops.joins(:avis).where(avis: {phase: "début de gestion"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_debut = Hash[@bops_avis_debut_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg1_arr = @bops.joins(:avis).where(avis: {phase: "CRG1"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_crg1 = Hash[@bops_avis_crg1_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg2_arr = @bops.joins(:avis).where(avis: {phase: "CRG2"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_crg2 = Hash[@bops_avis_crg2_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_user = @bops.joins(:user).pluck(:id, :nom).uniq.to_h
    @bops_user_id = @bops.joins(:user).pluck(:user_id, :nom).uniq.to_h
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  def filter_restitution
    @bops = Bop.where(numero_programme: params[:numero].to_i).order(code: :asc)
    @bops_user = @bops.joins(:user).pluck(:user_id).uniq
    if params[:avis].length != 3 ||  params[:users].length != @bops_user.count
      @avis_select = Avi.where(bop_id: @bops.pluck(:id))
      if params[:avis].length != 3
        @statut = params[:avis]
        @avis_select = @avis_select.select{ |a| @statut.include?(a.statut) }
      end

      if params[:users].length != @bops_user.count
        @users = params[:users].map(&:to_i)
        @avis_select = @avis_select.select{ |a| @users.include?(a.user_id) }
      end

      @bops_arr = @avis_select.pluck(:bop_id)
      @bops = @bops.where(id: @bops_arr)
    end

    @bops_avis_debut_arr = @bops.joins(:avis).where(avis: {phase: "début de gestion"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_debut = Hash[@bops_avis_debut_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg1_arr = @bops.joins(:avis).where(avis: {phase: "CRG1"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_crg1 = Hash[@bops_avis_crg1_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg2_arr = @bops.joins(:avis).where(avis: {phase: "CRG2"}).where.not(avis: {etat: "Brouillon"}).pluck(:id, :statut, "avis.id")
    @bops_avis_crg2 = Hash[@bops_avis_crg2_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_user = @bops.joins(:user).pluck(:id, :nom).to_h

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('liste_bops', partial: "pages/restitution_liste_bop")
        ]
      end
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

  def plan
  end

  def faq
  end

  private
  def returnPhase(date1,date2)
    if Date.today <= date1
      @phase = "début de gestion"
    elsif date1 < Date.today && Date.today <= date2
      @phase = "CRG1"
    elsif Date.today > date2
      @phase = "CRG2"
    end
    return @phase
  end

  def avisRepartition(avis, avis_vide)
    @avis_favorables = avis.select{|a| a.statut == 'Favorable'}.length
    @avis_reserves = avis.select{|a| a.statut =="Favorable avec réserve"}.length
    @avis_defavorables = avis.select{|a| a.statut =='Défavorable'}.length
    @avis = [@avis_favorables,@avis_reserves,@avis_defavorables,avis_vide]
    return @avis
  end

  def avisDateRepartition(avis,avis_vide)
    @avis_date_1 = avis.select{|a| a.date_reception <= Date.new(2023,3,1)}.length
    @avis_date_2 = avis.select{|a| a.date_reception > Date.new(2023,3,1) && a.date_reception <= Date.new(2023,3,15)}.length
    @avis_date_3 = avis.select{|a| a.date_reception > Date.new(2023,3,15) && a.date_reception <= Date.new(2023,3,31)}.length
    @avis_date_4 = avis.select{|a| a.date_reception > Date.new(2023,4,1)}.length
    @avis_date = [@avis_date_1,@avis_date_2,@avis_date_3,@avis_date_4,avis_vide]
    return @avis_date
  end

  def notesRepartition(avis, avis_total)
    @notes_sans_risque = avis.select{|a| a.statut =='Aucun risque'}.length
    @notes_moyen = avis.select{|a| a.statut =="Risques éventuels ou modérés"}.length
    @notes_risque = avis.select{|a| a.statut == 'Risques certains ou significatifs'}.length
    @notes_vide = avis_total - @notes_sans_risque - @notes_moyen - @notes_risque
    @notes = [@notes_sans_risque,@notes_moyen,@notes_risque,@notes_vide]
    return @notes
  end
end
