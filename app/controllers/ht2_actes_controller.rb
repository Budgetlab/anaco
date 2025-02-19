class Ht2ActesController < ApplicationController

  def new
    @acte = current_user.ht2_actes.new(type_acte: params[:type_acte])
    @liste_natures = ["Nature 1", "nature 2"]
  end

  def create
    @acte = current_user.ht2_actes.new(ht2_acte_params)
    @acte.etat = "En cours d'instruction"
    if @acte.save
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :new
    end
  end

  def edit
    @acte = Ht2Acte.find(params[:id])
    @etape = params[:etape].to_i || 1
    @liste_natures = ["Nature 1", "nature 2"]
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

  private

  def ht2_acte_params
    params.require(:ht2_acte).permit(:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global,
                                     :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte,
                                     :pre_instruction, :action, :sous_action, :activite, :lien_tf, :numero_tf,
                                     :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation,
                                     :proposition_decision, :commentaire_proposition_decision, :complexite, :observations,
                                     :user_id,:commentaire_disponibilite_credits, :commentaire_imputation_depense,
                                     :commentaire_consommation_credits, :commentaire_programmation, type_observations: [] )
  end
end
