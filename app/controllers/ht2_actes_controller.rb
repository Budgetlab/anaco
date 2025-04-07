class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_acte_ht2, only: [:edit, :update, :show, :destroy, :validate_acte]
  before_action :set_variables_form, only: [:edit, :validate_acte]

  def index
    @statut_user = current_user.statut
    @actes = @statut_user == 'admin' ? Ht2Acte.where(etat: 'clôturé').order(created_at: :desc) : current_user.ht2_actes.order(created_at: :desc)
    @q = @actes.ransack(params[:q])
    filtered_actes = @q.result(distinct: true)
    @actes_pre_instruction_all = filtered_actes&.where(etat: 'en pré-instruction')
    @pagy_pre_instruction, @actes_pre_instruction = pagy(@actes_pre_instruction_all, page_param: :page_pre_instruction)
    @actes_instruction_all = filtered_actes&.where(etat: "en cours d'instruction")
    @pagy_instruction, @actes_instruction = pagy(@actes_instruction_all, page_param: :page_instruction)
    @actes_validation_all = filtered_actes&.where(etat: 'en attente de validation')
    @pagy_validation, @actes_validation = pagy(@actes_validation_all, page_param: :page_validation)
    @actes_cloture_all = filtered_actes&.where(etat: 'clôturé')
    @pagy_cloture, @actes_cloture = pagy(@actes_cloture_all, page_param: :page_cloture)
    @actes_suspendu_all = filtered_actes&.where(etat: 'suspendu')
    @pagy_suspendu, @actes_suspendu = pagy(@actes_suspendu_all, page_param: :page_suspendu)

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
    # if params[:parent_id].present?
    #  acte_parent = Ht2Acte.find(params[:parent_id])
    #  @acte = acte_parent.duplicate_with_rich_text
    #  @acte.attributes = ht2_acte_params
    # else
    @acte = current_user.ht2_actes.new(ht2_acte_params)
    # end
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
      associate_centre_financier(@acte)
      @acte.update(date_cloture: Date.today) if @etape == 8
      path = @etape <= 6 ? edit_ht2_acte_path(@acte, etape: @etape) : ht2_actes_path
      @message = "Acte #{@acte.etat} enregistré avec succès."
      redirect_to path, notice: @message
    else
      render :edit
    end
  end

  def show
    @actes_groupe = @acte.numero_chorus.present? ? @acte.tous_actes_meme_chorus.order(created_at: :asc) : [@acte]
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
    @ht2_actes = current_user.statut == 'admin' ? Ht2Acte : current_user.ht2_actes
    @ht2_actes_clotures = @ht2_actes.where(etat: 'clôturé')
    @ht2_avis_decisions = @ht2_actes_clotures.where(type_acte: 'avis').group(:decision_finale).count
    @ht2_visa_decisions = @ht2_actes_clotures.where(type_acte: 'visa').group(:decision_finale).count
    @ht2_tf_decisions = @ht2_actes_clotures.where(type_acte: 'TF').group(:decision_finale).count
    @ht2_suspensions_motif = calculate_suspensions_stats(@ht2_actes_clotures)
    @actes_par_instructeur = @ht2_actes_clotures.group(:instructeur).count
    @actes_par_mois = calculate_actes_par_mois(@ht2_actes)
    @suspensions_distribution = calculate_suspensions_distribution(@ht2_actes_clotures)
  end

  private

  def ht2_acte_params
    params[:ht2_acte][:type_observations] = params[:ht2_acte][:type_observations]&.split(",") if params[:ht2_acte][:type_observations].is_a?(String)

    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :numero_tf,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :complexite, :observations,
                                     :user_id, :commentaire_disponibilite_credits, :commentaire_imputation_depense,
                                     :commentaire_consommation_credits, :commentaire_programmation, :valideur, :date_cloture,
                                     :decision_finale, type_observations: [],
                                     suspensions_attributes: [:id, :_destroy, :date_suspension, :motif, :observations, :date_reprise],
                                     echeanciers_attributes: [:id, :_destroy, :annee, :montant_ae, :montant_cp],
                                     poste_lignes_attributes: [:id, :_destroy, :centre_financier_code, :montant, :domaine_fonctionnel, :fonds, :compte_budgetaire, :code_activite, :axe_ministeriel])
  end

  def set_acte_ht2
    @acte = Ht2Acte.find(params[:id])
  end

  def set_variables_form
    if (params[:type_acte].present? && params[:type_acte] == 'avis') || @acte&.type_acte == 'avis'
      @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Avenant", "Convention", "Liste d'actes", "Transaction", "Autre"]
      @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'visa') || @acte&.type_acte == 'visa'
      @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Avenant", "Bail", "Bon de commande", "Convention", "Dotation en fonds propres", "Liste d'actes", "Prêt ou avance", "Remboursement de mise à disposition T3", "Subvention", "Subvention pour charges d'investissement", "Subvention pour charges d'investissement", "Transaction", "Transfert", "Autre"]
      @liste_decisions = ["Visa accordé", "Visa accordé avec observations", " Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    elsif (params[:type_acte].present? && params[:type_acte] == 'TF') || @acte&.type_acte == 'TF'
      @liste_natures = ["Affectation initiale","Affectation complémentaire","Retrait"]
      @liste_decisions = ["Visa accordé", "Visa accordé avec observations", " Refus de visa", "Retour sans décision (sans suite)", "Saisine a posteriori"]
    end
    @liste_types_observations = ["Compatibilité avec la programmation", "Construction de l’EJ", "Disponibilité des crédits", "Evaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Pièce(s) manquante(s)", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
    @liste_motifs_suspension = ["Erreur d’imputation", "Erreur dans la construction de l’EJ", "Mauvaise évaluation de la consommation des crédits", "Pièce(s) manquante(s)", "Problématique de compatibilité avec la programmation", "Problématique de disponibilité des crédits", "Problématique de soutenabilité", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
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

      puts 'lll'

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

  def calculate_actes_par_mois(actes)
    # Obtenir l'année en cours
    current_year = Date.today.year

    # Préparer un tableau pour chaque mois de l'année
    mois = (1..12).map do |month|
      debut_mois = Date.new(current_year, month, 1)
      fin_mois = Date.new(current_year, month, -1) # Dernier jour du mois

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
end
