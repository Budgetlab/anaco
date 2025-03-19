class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_acte_ht2, only: [:edit, :update, :show, :destroy, :validate_acte]
  before_action :set_variables_form, only: [:edit, :validate_acte]

  def index
    @actes = current_user.ht2_actes.order(created_at: :desc)
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
      path = @etape <= 6 ? edit_ht2_acte_path(@acte, etape: @etape) : ht2_actes_path
      redirect_to path
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

  private

  def ht2_acte_params
    params[:ht2_acte][:type_observations] = params[:ht2_acte][:type_observations]&.split(",") if params[:ht2_acte][:type_observations].is_a?(String)

    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :lien_tf, :numero_tf,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :complexite, :observations,
                                     :user_id, :commentaire_disponibilite_credits, :commentaire_imputation_depense,
                                     :commentaire_consommation_credits, :commentaire_programmation, :valideur,
                                     :decision_finale, type_observations: [], suspensions_attributes: [:id, :_destroy, :date_suspension, :motif, :observations, :date_reprise])
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
end
