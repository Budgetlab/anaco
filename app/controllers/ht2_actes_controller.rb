class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_variables_form, only: [:new, :edit, :validate_acte]

  def index
    @actes = current_user.ht2_actes.order(created_at: :desc)
    @q = @actes.ransack(params[:q])
    filtered_actes = @q.result(distinct: true)
    @pagy_pre_instruction, @actes_pre_instruction = pagy(filtered_actes&.where(etat: 'pre-instruction'))
    @pagy_instruction, @actes_instruction = pagy(filtered_actes&.where(etat: 'instruction'))
    @pagy_validation, @actes_validation = pagy(filtered_actes&.where(etat: 'attente validation'))
    @pagy_cloture, @actes_cloture = pagy(filtered_actes&.where(etat: 'cloture'))
  end

  def new
    @acte = current_user.ht2_actes.new(type_acte: params[:type_acte])
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
    @acte = Ht2Acte.find(params[:id])
    @etape = params[:etape].present? ? params[:etape].to_i : 1
    check_acte_conditions
  end

  def update
    @acte = Ht2Acte.find(params[:id])
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
    @acte = Ht2Acte.find(params[:id])
  end

  def validate_acte
    @acte = Ht2Acte.find(params[:id])
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
                                     :decision_finale, type_observations: [] )
  end

  def set_variables_form
    @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Avenant", "Convention", "Liste d'actes", "Transaction", "Autre"]
    @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable"]
    @liste_types_observations = ["Compatibilité avec la programmation", "Construction de l’EJ", "Disponibilité des crédits", "Evaluation de la consommation des crédits", "Fondement juridique", "Imputation", "Pièce(s) manquante(s)", "Risque au titre de la RGP", "Saisine a posteriori", "Saisine en dessous du seuil de soumission au contrôle", "Autre"]
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
    @conditions_met = @acte.instructeur.present? && @acte.nature.present? && @acte.montant_ae.present? && @acte.date_chorus.present? && @acte.disponibilite_credits.present? && @acte.imputation_depense.present? && @acte.consommation_credits.present? && @acte.programmation.present?
  end
end
