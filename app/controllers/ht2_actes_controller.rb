class Ht2ActesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_liste_natures, only: [:new, :edit]

  def index
    @actes = current_user.ht2_actes.order(created_at: :desc)
  end

  def new
    @acte = current_user.ht2_actes.new(type_acte: params[:type_acte])
  end

  def create
    @acte = current_user.ht2_actes.new(ht2_acte_params)
    if @acte.save
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :new
    end
  end

  def edit
    @acte = Ht2Acte.find(params[:id])
    @etape = params[:etape].to_i || 1
    @liste_decisions = ["Favorable", "Favorable avec observations", "Défavorable"]
  end

  def update
    @acte = Ht2Acte.find(params[:id])
    @etape = params[:etape].to_i || 1
    if @acte.update(ht2_acte_params)
      redirect_to edit_ht2_acte_path(@acte, etape: @etape)
    else
      render :edit
    end
  end

  def show
    @acte = Ht2Acte.find(params[:id])
  end

  private

  def ht2_acte_params
    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :lien_tf, :numero_tf,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :complexite, :observations,
                                     :user_id, :commentaire_disponibilite_credits, :commentaire_imputation_depense,
                                     :commentaire_consommation_credits, :commentaire_programmation, type_observations: [] )
  end

  def set_liste_natures
    @liste_natures = ["Accord cadre à bons de commande", "Accord cadre à marchés subséquents", "Autre contrat", "Avenant", "Convention", "Liste d'actes", "Transaction", "Autre"]
  end
end
