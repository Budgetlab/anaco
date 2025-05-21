class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_acte_ht2, only: [:edit, :update, :show, :destroy, :validate_acte]
  before_action :set_variables_form, only: [:edit, :validate_acte]
  before_action :authenticate_admin!, only: [:synthese_utilisateurs]

  def index
    @statut_user = current_user.statut
    @actes = @statut_user == 'admin' ? Ht2Acte.where(etat: 'clôturé').includes(:user).order(date_cloture: :desc) : current_user.ht2_actes.order(created_at: :desc)
    @q = @actes.ransack(params[:q], search_key: :q)
    filtered_actes = @q.result(distinct: true)
    @q_instruction = filtered_actes.where(etat: "en cours d'instruction").ransack(params[:q_instruction], search_key: :q_instruction)
    @q_validation = filtered_actes.where(etat: 'en attente de validation').ransack(params[:q_validation], search_key: :q_validation)
    @q_validation_chorus = filtered_actes.where(etat: 'en attente de validation Chorus').ransack(params[:q_validation], search_key: :q_validation)
    @q_cloture = filtered_actes.where(etat: 'clôturé').ransack(params[:q_cloture], search_key: :q_cloture)

    @actes_pre_instruction_all = filtered_actes.where(etat: 'en pré-instruction')
    @actes_instruction_all = @q_instruction.result(distinct: true)
    @actes_validation_all = @q_validation.result(distinct: true)
    @actes_validation_chorus_all = @q_validation_chorus.result(distinct: true)
    @actes_suspendu_all = filtered_actes.where(etat: 'suspendu').includes(:suspensions)
    @actes_cloture_all = @q_cloture.result(distinct: true)

    @pagy_pre_instruction, @actes_pre_instruction = pagy(@actes_pre_instruction_all, page_param: :page_pre_instruction)
    @pagy_instruction, @actes_instruction = pagy(@actes_instruction_all, page_param: :page_instruction)
    @pagy_validation, @actes_validation = pagy(@actes_validation_all, page_param: :page_validation)
    @pagy_validation_chorus, @actes_validation_chorus = pagy(@actes_validation_chorus_all, page_param: :page_validation_chorus)
    @pagy_suspendu, @actes_suspendu = pagy(@actes_suspendu_all, page_param: :page_suspendu)
    @pagy_cloture, @actes_cloture = pagy(@actes_cloture_all, page_param: :page_cloture)

    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  def new
    if params[:type_acte].present?
      @acte = current_user.ht2_actes.new(type_acte: params[:type_acte])
    elsif params[:id].present?
      id = params[:id]
      acte_parent = Ht2Acte.find(id)
      @acte = current_user.ht2_actes.new(acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'date_chorus', 'numero_chorus', 'etat'))
    elsif params[:parent_id].present?
      id = params[:parent_id]
      @acte_parent = Ht2Acte.find(id)
      @acte = current_user.ht2_actes.new(@acte_parent.attributes.except('id', 'created_at', 'updated_at', 'instructeur', 'date_chorus', 'etat'))
      @saisine = true
    else
      @acte = current_user.ht2_actes.new(type_acte: 'avis')
    end
    set_variables_form
  end

  def create
    @acte = current_user.ht2_actes.new(ht2_acte_params)
    if @acte.save
      associate_centre_financier(@acte)
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :new
    end
  end

  def edit
    @etape = params[:etape].present? ? params[:etape].to_i : 1
    check_acte_conditions
  end

  def update
    @etape = params[:etape].to_i || 1
    # Vérifier si le paramètre d'action est envoyé
    @acte.etat = params[:submit_action] if params[:submit_action].present?
    if @acte.update(ht2_acte_params)
      # Association du centre financier
      associate_centre_financier(@acte) if @etape == 2
      # Calculer le délai de traitement si l'acte est clôturé
      set_delai_traitement(@acte) if @acte.etat == 'clôturé'
      # Déterminer le chemin de redirection
      path = @etape <= 3 ? edit_ht2_acte_path(@acte, etape: @etape) : ht2_actes_path
      @message = "Acte #{@acte.etat} enregistré avec succès."
      redirect_to path, notice: @message
    else
      render :edit
    end
  end

  def show
    @actes_groupe = @acte.numero_chorus.present? ? @acte.tous_actes_meme_chorus.includes(:suspensions, :echeanciers, :poste_lignes).order(created_at: :asc) : [@acte]
    @acte_courant = @acte
  end

  def destroy
    @acte&.destroy
    redirect_to ht2_actes_path
  end

  def validate_acte; end

  def check_chorus_number
    numero_chorus = params[:numero_chorus]
    acte_id = params[:acte_id]
    if numero_chorus.present?
      actes_meme_chorus = current_user.ht2_actes.where(numero_chorus: numero_chorus)
      actes_meme_chorus = actes_meme_chorus.where.not(id: acte_id) if acte_id.present?
      actes_meme_chorus_count = actes_meme_chorus.count
    else
      actes_meme_chorus_count = 0
    end
    render json: { exists: actes_meme_chorus_count.positive? }
  end

  def synthese
    @statut_user = current_user.statut
    # Récupérer tous les programmes disponibles pour le filtre
    @programmes = if @statut_user == 'admin'
                    Programme.all.order(numero: :asc)
                  else
                    Programme.joins(centre_financiers: { ht2_actes: :user })
                             .where(ht2_actes: { user_id: current_user.id })
                             .distinct
                             .order(numero: :asc)
                  end
    # chargement des actes en fonction du profil
    @ht2_actes = @statut_user == 'admin' ? Ht2Acte : current_user.ht2_actes
    # Récupérer le programme sélectionné (s'il y en a un)
    @selected_programme_id = params[:programme_id].presence
    # Filtrer par programme si un programme est sélectionné
    if @selected_programme_id.present?
      @ht2_actes = @ht2_actes.joins(centre_financiers: :programme)
                             .where(centre_financiers: { programme_id: @selected_programme_id })
    end
    # Précharger les associations nécessaires
    @ht2_actes = @ht2_actes.includes(:suspensions)
    # Réutiliser la même scope pour les actes clôturés
    @ht2_actes_clotures = @ht2_actes.where(etat: 'clôturé')
    # graphes
    @ht2_avis_decisions = @ht2_actes_clotures.where(type_acte: 'avis').group(:decision_finale).count
    @ht2_visa_decisions = @ht2_actes_clotures.where(type_acte: 'visa').group(:decision_finale).count
    @ht2_tf_decisions = @ht2_actes_clotures.where(type_acte: 'TF').group(:decision_finale).count
    @ht2_suspensions_motif = calculate_suspensions_stats(@ht2_actes_clotures)
    @actes_par_mois = calculate_actes_par_mois(@ht2_actes, @statut_user == 'admin')
    @suspensions_distribution = calculate_suspensions_distribution(@ht2_actes_clotures)
    @top_suspension_motifs_chart_data = calculate_top_motifs(@ht2_actes_clotures)
    # Construire la requête agrégée
    top_programmes = Programme
                       .select('programmes.id, programmes.numero, COUNT(ht2_actes.id) AS actes_count')
                       .joins(centre_financiers: :ht2_actes)
                       .merge(@ht2_actes_clotures)
                       .group('programmes.id')
                       .order('actes_count DESC')
                       .limit(10)
    @top_programmes_chart_data = top_programmes.map { |p| { name: p.numero, y: p.actes_count.to_i } }
    top_programmes_suspensions = Programme
                                   .select('programmes.id, programmes.numero, COUNT(suspensions.id) AS suspensions_count')
                                   .joins(centre_financiers: { ht2_actes: :suspensions })
                                   .merge(@ht2_actes_clotures)
                                   .group('programmes.id')
                                   .order('suspensions_count DESC')
                                   .limit(10)
    @top_programmes_suspensions_chart_data = top_programmes_suspensions.map { |p| { name: p.numero, y: p.suspensions_count.to_i } }

    if @statut_user == 'admin'
      @stacked_type_acte_data = calculate_repartion(@ht2_actes_clotures)
    else
      @repartition_acte = @ht2_actes_clotures.group(:type_acte).count.map { |type_acte, count| { name: type_acte, y: count } }
    end
  end

  def synthese_utilisateurs
    @users_cbr = User.where(statut: 'CBR').order(nom: :asc)
    @users_dcb = User.where(statut: 'DCB').order(nom: :asc)

    @stats_cbr = user_ht2_stats(@users_cbr)
    @stats_dcb = user_ht2_stats(@users_dcb)
  end

  private

  def ht2_acte_params
    params[:ht2_acte][:type_observations] = params[:ht2_acte][:type_observations]&.split(",") if params[:ht2_acte][:type_observations].is_a?(String)

    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :numero_tf, :date_limite,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :complexite, :observations,
                                     :user_id, :commentaire_disponibilite_credits, :commentaire_imputation_depense,
                                     :commentaire_consommation_credits, :commentaire_programmation, :valideur, :date_cloture,
                                     :decision_finale, :numero_utilisateur, :delai_traitement, type_observations: [],
                                     suspensions_attributes: [:id, :_destroy, :date_suspension, :motif, :observations, :date_reprise],
                                     echeanciers_attributes: [:id, :_destroy, :annee, :montant_ae, :montant_cp],
                                     poste_lignes_attributes: [:id, :_destroy,:numero, :centre_financier_code, :montant, :domaine_fonctionnel, :fonds, :compte_budgetaire, :code_activite, :axe_ministeriel])
  end

  def set_acte_ht2
    @acte = Ht2Acte.find(params[:id])
  end

  def set_variables_form
    if (params[:type_acte].present? && params[:type_acte] == 'avis') || @acte&.type_acte == 'avis'
      @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Avenant", "Convention", "Liste d'actes", "Transaction", "Autre"]
      @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable", "Retour sans décision (sans suite)", "Saisine a posteriori"]
      @liste_types_observations = ["Compatibilité avec la programmation", "Construction de l’EJ", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Pièce(s) manquante(s)", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'visa') || @acte&.type_acte == 'visa'
      @liste_natures = ["Autre contrat", "Avenant", "Bail", "Bon de commande", "Convention", "Décision diverse", "Dotation en fonds propres", "Liste d'actes","Marché unique", "Marché à tranches","Marché mixte","MAPA unique", "MAPA à tranches", "MAPA à bons de commande", "MAPA mixte","Prêt ou avance", "Remboursement de mise à disposition T3", "Subvention", "Subvention pour charges d'investissement", "Subvention pour charges de service public", "Transaction", "Transfert", "Autre"]
      @liste_types_observations = ["Compatibilité avec la programmation", "Construction de l’EJ", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Pièce(s) manquante(s)", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
      @liste_decisions = ["Visa accordé", "Visa accordé avec observations", "Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'TF') || @acte&.type_acte == 'TF'
      @liste_natures = ["Affectation initiale", "Affectation complémentaire", "Retrait"]
      @liste_decisions = ["Visa accordé", "Visa accordé avec observations", "Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
      @liste_types_observations = ["Compatibilité avec la programmation", "Disponibilité des crédits", "Évaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Pièce(s) manquante(s)", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
    end
    @liste_motifs_suspension = ["Erreur d’imputation", "Erreur dans la construction de l’EJ", "Mauvaise évaluation de la consommation des crédits", "Pièce(s) manquante(s)", "Problématique de compatibilité avec la programmation", "Problématique de disponibilité des crédits", "Problématique de soutenabilité", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
  end

  def associate_centre_financier(acte)
    code = acte.centre_financier_code
    if code.present?
      centre = CentreFinancier.find_by(code: code)
      if centre
        # Supprimer les associations existantes et ajouter la nouvelle
        acte.centre_financiers.destroy_all
        acte.centre_financiers << centre
      end
    else
      # Si pas de code, supprimer toutes les associations
      acte.centre_financiers.destroy_all
    end
  end

  def check_acte_conditions
    @conditions_met = @acte.etat != "en pré-instruction" && @acte.instructeur.present? && @acte.nature.present? && @acte.montant_ae.present? && @acte.date_chorus.present? && !@acte.disponibilite_credits.nil? && !@acte.imputation_depense.nil? && !@acte.consommation_credits.nil? && !@acte.programmation.nil?
  end

  def calculate_suspensions_stats(actes)
    # Récupérer les statistiques des suspensions par type d'acte
    stats = []

    # Pour chaque type d'acte (visa et avis)
    ['avis', 'visa', 'TF'].each do |type_acte|
      # Trouver tous les actes de ce type
      actes_type = actes.where(type_acte: type_acte)

      # Obtenir toutes les suspensions liées à ces actes
      suspensions_ids = Suspension.where(ht2_acte_id: actes_type.pluck(:id)).pluck(:id)

      # Compter les occurrences de chaque motif
      motifs_count = Suspension.where(id: suspensions_ids).group(:motif).count

      # Formater les données pour le frontend
      motifs_data = motifs_count.map do |motif, count|
        { motif: motif, count: count }
      end

      # Ajouter les statistiques pour ce type d'acte
      stats << {
        type_acte: type_acte,
        total_suspensions: suspensions_ids.size,
        motifs: motifs_data
      }
    end

    stats
  end

  def calculate_actes_par_mois(actes, admin)
    # Obtenir l'année en cours
    current_year = Date.today.year

    # Préparer un tableau pour chaque mois de l'année
    mois = (1..12).map do |month|
      debut_mois = Date.new(current_year, month, 1)
      fin_mois = Date.new(current_year, month, -1) # Dernier jour du mois
      if admin
        # Initialiser les compteurs par profil
        created_cbr = actes
                        .joins(:user)
                        .where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois)
                        .where(users: { statut: 'CBR' }).count

        created_dcb = actes
                        .joins(:user)
                        .where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois)
                        .where(users: { statut: 'DCB' }).count

        closed_cbr = actes
                       .joins(:user)
                       .where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                       .where(etat: 'clôturé', users: { statut: 'CBR' }).count

        closed_dcb = actes
                       .joins(:user)
                       .where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                       .where(etat: 'clôturé', users: { statut: 'DCB' }).count

        {
          mois: I18n.l(debut_mois, format: '%B'),
          created_cbr: created_cbr,
          created_dcb: created_dcb,
          closed_cbr: closed_cbr,
          closed_dcb: closed_dcb
        }
      else
        # Compter les actes créés ce mois
        actes_crees = actes.where('date_chorus >= ? AND date_chorus <= ?', debut_mois, fin_mois).count

        # Compter les actes clôturés ce mois
        actes_clotures = actes.where('date_cloture >= ? AND date_cloture <= ?', debut_mois, fin_mois)
                              .where(etat: 'clôturé')
                              .count

        {
          mois: I18n.l(debut_mois, format: '%B'), # Nom du mois en français
          actes_crees: actes_crees,
          actes_clotures: actes_clotures
        }
      end
    end

    mois
  end

  def calculate_suspensions_distribution(actes)
    # Compter le nombre de suspensions pour chaque acte
    suspensions_par_acte = actes.map do |acte|
      acte.suspensions.count
    end

    # Trouver le nombre maximum de suspensions pour un acte
    max_suspensions = suspensions_par_acte.max || 0

    # Préparer le hash pour compter les actes par nombre de suspensions
    distribution = Hash.new(0)

    # Compter les actes pour chaque nombre de suspensions
    suspensions_par_acte.each do |count|
      distribution[count] += 1
    end

    # Transformer en tableau pour tous les nombres de 0 à max_suspensions
    result = []
    (0..max_suspensions).each do |i|
      result << {
        nombre_suspensions: i,
        nombre_actes: distribution[i]
      }
    end

    result
  end

  def calculate_repartion(actes)
    # Tous les ht2_actes visibles
    all_actes = actes
    dcb_actes = actes.joins(:user).where(users: { statut: 'DCB' })
    cbr_actes = actes.joins(:user).where(users: { statut: 'CBR' })

    # Regrouper par type_acte
    total_counts = all_actes.group(:type_acte).count
    dcb_counts = dcb_actes.group(:type_acte).count
    cbr_counts = cbr_actes.group(:type_acte).count

    # Types d'actes possibles (ajustable si dynamique)
    types_actes = ['TF', 'visa', 'avis']

    # Construire les séries pour Highcharts
    result = types_actes.map do |type|
      {
        name: type,
        data: [
          total_counts[type] || 0,
          dcb_counts[type] || 0,
          cbr_counts[type] || 0
        ]
      }
    end
    result
  end

  def calculate_top_motifs(actes)
    ht2_acte_ids = actes.pluck(:id)

    top_suspension_motifs = Suspension
                              .where(ht2_acte_id: ht2_acte_ids)
                              .group(:motif)
                              .order(Arel.sql('COUNT(*) DESC'))
                              .limit(5)
                              .count
    top_suspension_motifs_chart_data = top_suspension_motifs.map do |motif, count|
      {
        name: motif,
        y: count
      }
    end
    top_suspension_motifs_chart_data
  end

  def set_delai_traitement(acte)
    # S'assurer que les dates nécessaires sont présentes
    if acte.etat == 'clôturé' && acte.date_chorus.present? && acte.date_cloture.present?
      # Calculer la durée totale en jours
      delai_total = (acte.date_cloture.to_date - acte.date_chorus.to_date).to_i

      # Calculer le délai en fonction du type d'acte et des suspensions
      delai_final = if acte.suspensions.empty?
                      delai_total
                    elsif acte.type_acte == 'avis'
                      # Pour les avis, soustraire la durée de chaque suspension
                      duree_suspensions = acte.suspensions.sum do |suspension|
                        if suspension.date_suspension.present? && suspension.date_reprise.present?
                          (suspension.date_reprise.to_date - suspension.date_suspension.to_date).to_i
                        else
                          0
                        end
                      end

                      # Délai total moins durée des suspensions
                      [delai_total - duree_suspensions, 0].max
                    elsif acte.type_acte == 'visa' || acte.type_acte == 'TF'
                      # Pour les visas, prendre le délai entre la dernière reprise et la clôture
                      derniere_suspension = acte.suspensions.order(date_reprise: :desc).first

                      if derniere_suspension&.date_reprise.present?
                        (acte.date_cloture.to_date - derniere_suspension.date_reprise.to_date).to_i
                      else
                        delai_total
                      end
                    else
                      # Si type inconnu, retourner le délai total
                      delai_total
                    end

      # Mettre à jour la colonne delai_traitement sans déclencher les callbacks
      acte.update_column(:delai_traitement, delai_final)
    end
  end

  def user_ht2_stats(users)
    users.includes(:ht2_actes).map do |user|
      ht2_actes = user.ht2_actes

      actes_clotures = ht2_actes.where(etat: 'clôturé')
      actes_non_clotures = ht2_actes.where.not(etat: 'clôturé')

      actes_avec_suspension_ids = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).pluck(:ht2_acte_id).uniq
      actes_avec_suspensions_count = actes_avec_suspension_ids.size

      suspensions_count = Suspension.where(ht2_acte_id: actes_clotures.pluck(:id)).count

      {
        user: user,
        actes_clotures_count: actes_clotures.count,
        actes_non_clotures_count: actes_non_clotures.count,
        actes_avec_suspensions_count: actes_avec_suspensions_count,
        suspensions_count: suspensions_count,
        delai_moyen: actes_clotures.delai_moyen_traitement,
      }
    end
  end
end
