class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  def index
    @date_alert1 = Date.new(2023, 3, 15)
    @date_alert2 = Date.new(2023, 6, 15)
    if current_user.statut == 'CBR' || current_user.statut == 'DCB'
      @avis_remplis = current_user.avis
      @avis_total = current_user.bops.where(dotation: [nil, 'complete','T2','HT2']).count
      if current_user.statut == 'DCB'
        @bops_consultation = Bop.where(consultant: current_user.id).where.not(user_id: current_user.id)
        @bops_consultation_id = @bops_consultation.pluck(:id)
        @avis_to_read = Avi.where(bop_id: @bops_consultation_id, etat: 'En attente de lecture').count
      end
    else
      @avis_remplis = Avi.all
      @avis_total = Bop.where(dotation: [nil, 'complete','T2','HT2']).count
    end
    @avis_valid = @avis_remplis.where('phase = ? AND etat != ?', 'début de gestion', 'Brouillon')
    @avis_vide = @avis_total - @avis_valid.count
    @avis = avisRepartition(@avis_valid, @avis_vide)
    @avis_crg1 = @avis_valid.select{ |a| a.is_crg1 == true }.count
    @avis_delai = @avis_valid.select{ |a| a.is_delai == false }.count
    @notes1 = []
    if @date1 < Date.today
      @avis_valid_crg1 = @avis_remplis.where('phase = ? AND etat != ?', 'CRG1', 'Brouillon')
      @notes1 = notesRepartition(@avis_valid_crg1, @avis_crg1)
    end
    @notes2 = []
    if @date2 < Date.today
      @avis_valid_crg2 = @avis_remplis.where('phase = ? AND etat != ?', 'CRG2', 'Brouillon')
      @notes2 = notesRepartition(@avis_valid_crg2, @avis_total)
    end
  end

  def restitutions
    @total_programmes = Bop.pluck(:numero_programme).uniq.length
    if current_user.statut == 'admin'
      @programmes = Bop.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    elsif	current_user.statut == 'DCB'
      @programmes = Bop.where('user_id = ? OR consultant = ?',current_user.id, current_user.id).order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    elsif current_user.statut == 'CBR'
      @programmes = current_user.bops.order(numero_programme: :asc).pluck(:numero_programme, :nom_programme).uniq
    else
      redirect_to root_path
    end
    @liste_avis_programme = Avi.where('etat != ?', 'Brouillon').includes(:bop).pluck(:numero_programme)
    @liste_bop_programme = Bop.pluck(:numero_programme)
    @bops_count = Bop.where(dotation: [nil, 'complete','T2','HT2']).count
    @avis_d = Avi.where(phase: 'début de gestion').where.not(etat: 'Brouillon')
    @avis_vide = @bops_count - @avis_d.count
    @avis = avisRepartition(@avis_d,@avis_vide)
    @avis_date = avisDateRepartition(@avis_d,@avis_vide)
    @avis_iscrg1 = @avis_d.select{|a| a.is_crg1 == true}.length
    @statuts_debut = [@avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_d.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_d.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_d.count ]
    @statuts_crg1 = [0,0,0,@bops_count]
    if @date1 < Date.today
      @avis_crg1 = Avi.where(phase: 'CRG1').where.not(etat: 'Brouillon')
      @statuts_positive = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count
      @statuts_nul = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count
      @statuts_negative = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count
      @statuts_vide = @bops_count - @avis_d.select { |a| a.is_crg1 == false}.count - @avis_crg1.count
      @statuts_crg1 = [@statuts_positive, @statuts_nul, @statuts_negative, @statuts_vide]
    end
    @statuts_crg2 = [0,0,0,@bops_count]
    if @date2 < Date.today
      @avis_crg2 = Avi.where(phase: 'CRG2').where.not(etat: 'Brouillon')
      @statuts_crg2 = [@avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_crg2.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_crg2.count ]
    end
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
  end
  def restitution_programme
    @numero = params[:programme]
    @bops = Bop.where(numero_programme: @numero).order(code: :asc)
    @bops_actifs = @bops.where(dotation: [nil, 'complete','T2','HT2'])
    @bops_id_all = @bops.pluck(:id)
    @bops_count_all = @bops_id_all.length
    @bops_id = @bops_actifs.pluck(:id)
    @bops_count = @bops_id.length
    @ministere = @bops.first.ministere

    @avis = Avi.where(bop_id: @bops_id, phase: @phase).where('etat != ?','Brouillon')
    @array = @avis.pluck(:ae_i, :cp_i, :t2_i, :etpt_i,:ae_f, :cp_f, :t2_f, :etpt_f )
    #@data = @array.transpose.map(&:sum)
    @data = [@array.sum { |a,b,c,d,e,f,g,h| a}, @array.sum { |a,b,c,d,e,f,g,h| b},@array.sum { |a,b,c,d,e,f,g,h| c},@array.sum { |a,b,c,d,e,f,g,h| d},@array.sum { |a,b,c,d,e,f,g,h| e}, @array.sum { |a,b,c,d,e,f,g,h| f}, @array.sum { |a,b,c,d,e,f,g,h| g},@array.sum { |a,b,c,d,e,f,g,h| h}]

    @avis_d = Avi.where(bop_id: @bops_id, phase: 'début de gestion').where.not(etat: 'Brouillon')
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
      @avis_crg1 = Avi.where(bop_id: @bops_id, phase: 'CRG1').where.not(etat: 'Brouillon')
      @statuts_positive = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count
      @statuts_nul = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count
      @statuts_negative = @avis_d.select { |a| a.is_crg1 == false && (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count + @avis_crg1.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count
      @statuts_vide = @bops_count - @avis_d.select { |a| a.is_crg1 == false}.count - @avis_crg1.count
      @statuts_crg1 = [@statuts_positive, @statuts_nul, @statuts_negative, @statuts_vide]
    end
    @statuts_crg2 = [0,0,0,@bops_count]
    if @date2 < Date.today
      @avis_crg2 = Avi.where(bop_id: @bops_id, phase: 'CRG2').where.not(etat: 'Brouillon')
      @statuts_crg2 = [@avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).positive? }.count, @avis_crg2.select { |a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).zero? }.count, @avis_crg2.select {|a| (a.ae_i + a.t2_i - a.ae_f - a.t2_f).negative? }.count, @bops_count-@avis_crg2.count ]
      @array_c = @avis_crg1.pluck(:ae_i, :cp_i, :t2_i, :etpt_i,:ae_f, :cp_f, :t2_f, :etpt_f )
      #@data_c = @array_c.transpose.map(&:sum)
      @data_c = [@array_c.sum { |a,b,c,d,e,f,g,h| a}, @array_c.sum { |a,b,c,d,e,f,g,h| b},@array_c.sum { |a,b,c,d,e,f,g,h| c},@array_c.sum { |a,b,c,d,e,f,g,h| d},@array_c.sum { |a,b,c,d,e,f,g,h| e}, @array_c.sum { |a,b,c,d,e,f,g,h| f}, @array_c.sum { |a,b,c,d,e,f,g,h| g},@array_c.sum { |a,b,c,d,e,f,g,h| h}]
    end
    @notesbar = [[@statuts_debut[0], @statuts_crg1[0], @statuts_crg2[0]], [@statuts_debut[1], @statuts_crg1[1], @statuts_crg2[1]], [@statuts_debut[2], @statuts_crg1[2], @statuts_crg2[2]], [@statuts_debut[3], @statuts_crg1[3], @statuts_crg2[3]]]
    @bops_avis_debut_arr = @bops.joins(:avis).where(avis: {phase: 'début de gestion'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
    @bops_avis_debut = Hash[@bops_avis_debut_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg1_arr = @bops.joins(:avis).where(avis: {phase: 'CRG1'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
    @bops_avis_crg1 = Hash[@bops_avis_crg1_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg2_arr = @bops.joins(:avis).where(avis: {phase: 'CRG2'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
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

    @bops_avis_debut_arr = @bops.joins(:avis).where(avis: {phase: 'début de gestion'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
    @bops_avis_debut = Hash[@bops_avis_debut_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg1_arr = @bops.joins(:avis).where(avis: {phase: 'CRG1'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
    @bops_avis_crg1 = Hash[@bops_avis_crg1_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_avis_crg2_arr = @bops.joins(:avis).where(avis: {phase: 'CRG2'}).where.not(avis: {etat: 'Brouillon'}).pluck(:id, :statut, 'avis.id')
    @bops_avis_crg2 = Hash[@bops_avis_crg2_arr.collect {|a| [a[0],a[1..2]]}]
    @bops_user = @bops.joins(:user).pluck(:id, :nom).to_h

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('liste_bops', partial: 'pages/restitution_liste_bop')
        ]
      end
    end
  end

  def suivi
    redirect_to root_path and return unless current_user.statut == 'admin'

    @users = User.where(statut: ['CBR','DCB'])
    @users_array = []
    @users_array_crg1 = []
    @users_array_crg2 = []

    @bops_all = Bop.where(dotation: [nil, 'complete', 'T2', 'HT2'])
    @avis = Avi.where(phase: 'début de gestion').select(:user_id, :etat, :statut, :is_crg1, :bop_id)
    @notes1 = Avi.where(phase: 'CRG1').select(:user_id, :etat, :statut, :bop_id)
    @notes2 = Avi.where(phase: 'CRG2').select(:user_id, :etat, :statut, :bop_id)

    @users.each do |user|
      @bops_actifs = @bops_all.select{ |b| b.user_id == user.id }.length
      @avis_favorables = @avis.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Favorable' }.length
      @avis_favorables_reserve = @avis.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Favorable avec réserve' }.length
      @avis_defavorables = @avis.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Défavorable' }.length
      @avis_brouillon = @avis.select { |a| a.user_id == user.id && a.etat == 'Brouillon' }.length
      @avis_vide = @bops_actifs - @avis.select { |a| a.user_id == user.id }.length
      @taux = ((@avis.select { |a| a.user_id == user.id && a.etat != 'Brouillon'}.length.to_f/@bops_actifs.to_f)*100).round
      @users_array << [user.nom, @bops_actifs, @avis_vide, @avis_brouillon, @avis_favorables, @avis_favorables_reserve, @avis_defavorables, @taux]

      @bops_crg1 = @avis.select { |a| a.user_id == user.id && a.is_crg1 == true && a.etat != 'Brouillon'}.length
      @notes1_brouillon = @notes1.select { |a| a.user_id == user.id && a.etat == 'Brouillon' }.length
      @notes1_risque_faible = @notes1.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Aucun risque' }.length
      @notes1_risque_modere = @notes1.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Risques éventuels ou modérés' }.length
      @notes1_risque_significatifs = @notes1.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Risques certains ou significatifs' }.length
      @taux_n1 = if @bops_crg1 == 0
                   0
                 else
                   (((@notes1_risque_faible+@notes1_risque_modere+@notes1_risque_significatifs).to_f/@bops_crg1.to_f)*100).round
                 end
      @users_array_crg1 << [user.nom, @bops_crg1, @notes1_brouillon, @notes1_risque_faible, @notes1_risque_modere, @notes1_risque_significatifs, @taux_n1]

      @notes2_brouillon = @notes1.select { |a| a.user_id == user.id && a.etat == 'Brouillon' }.length
      @notes2_risque_faible = @notes2.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Aucun risque' }.length
      @notes2_risque_modere = @notes2.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Risques éventuels ou modérés' }.length
      @notes2_risque_significatifs = @notes2.select { |a| a.user_id == user.id && a.etat != 'Brouillon' && a.statut == 'Risques certains ou significatifs' }.length
      @taux_n2 = (((@notes2_risque_faible+@notes2_risque_modere+@notes2_risque_significatifs).to_f/@bops_actifs.to_f)*100).round
      @users_array_crg2 << [user.nom, @bops_actifs, @notes2_brouillon, @notes2_risque_faible, @notes2_risque_modere, @notes2_risque_significatifs, @taux_n2]
    end
    @users_array = @users_array.sort_by { |e| -e[7]}
    @users_array_crg1 = @users_array_crg1.sort_by { |e| -e[6]}
    @users_array_crg2 = @users_array_crg2.sort_by { |e| -e[6]}
    @dcb = @users.select { |u| u.statut == 'DCB'}
    @dcb_array = []
    @dcb_array_crg1 = []
    @dcb_array_crg2 = []
    @dcb.each do |dcb|
      @bops_arr = @bops_all.select{ |b| b.consultant == dcb.id }.pluck(:id)
      @bops_actifs = @bops_arr.length
      @avis_lu = @avis.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'Lu'}.length
      @avis_en_attente = @avis.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'En attente de lecture'}.length
      @avis_non_recu = @bops_actifs - @avis_lu - @avis_en_attente
      @taux = if @avis_lu == 0
                0
              else
                ((@avis_lu.to_f/(@avis_lu+@avis_en_attente).to_f)*100).round
              end
      @dcb_array << [dcb.nom, @bops_actifs, @avis_non_recu, @avis_en_attente, @avis_lu, @taux]
      @bops_crg1_actifs = @avis.select { |a| @bops_arr.include?(a.bop_id) && a.is_crg1 == true && a.etat != 'Brouillon'}.length
      @notes1_lu = @notes1.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'Lu'}.length
      @notes1_en_attente = @notes1.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'En attente de lecture'}.length
      @notes1_non_recu = @bops_crg1_actifs - @notes1_lu - @notes1_en_attente
      @taux_n1 = if @notes1_lu == 0
                0
              else
                ((@notes1_lu.to_f/(@notes1_lu+@notes1_en_attente).to_f)*100).round
              end
      @dcb_array_crg1 << [dcb.nom, @bops_crg1_actifs, @notes1_non_recu, @notes1_en_attente, @notes1_lu, @taux_n1]
      @notes2_lu = @notes2.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'Lu'}.length
      @notes2_en_attente = @notes2.select { |a| @bops_arr.include?(a.bop_id) && a.etat == 'En attente de lecture'}.length
      @notes2_non_recu = @bops_actifs - @notes2_lu - @notes2_en_attente
      @taux_n2 = if @notes2_lu == 0
                   0
                 else
                   ((@notes2_lu.to_f/(@notes2_lu+@notes2_en_attente).to_f)*100).round
                 end
      @dcb_array_crg2 << [dcb.nom, @bops_actifs, @notes2_non_recu, @notes2_en_attente, @notes2_lu, @taux_n2]

    end
    @dcb_array = @dcb_array.sort_by { |e| -e[5]}
    @dcb_array_crg1 = @dcb_array_crg1.sort_by { |e| -e[5]}
    @dcb_array_crg2 = @dcb_array_crg2.sort_by { |e| -e[5]}
    respond_to do |format|
      format.html
      format.xlsx
    end

  end
  def error_404
    if params[:path] && params[:path] == '500'
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

  def avisRepartition(avis, avis_vide)
    @avis_favorables = avis.select{|a| a.statut == 'Favorable'}.length
    @avis_reserves = avis.select{|a| a.statut =='Favorable avec réserve'}.length
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
    @notes_moyen = avis.select{|a| a.statut =='Risques éventuels ou modérés'}.length
    @notes_risque = avis.select{|a| a.statut == 'Risques certains ou significatifs'}.length
    @notes_vide = avis_total - @notes_sans_risque - @notes_moyen - @notes_risque
    @notes = [@notes_sans_risque,@notes_moyen,@notes_risque,@notes_vide]
    return @notes
  end
end
