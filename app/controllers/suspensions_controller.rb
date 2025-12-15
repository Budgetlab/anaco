class SuspensionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_suspension, only: [:edit, :update, :destroy, :refus_suspension, :modal_delete, :modal_refus_suspension]
  before_action :set_acte, only: [:edit, :update, :destroy, :refus_suspension, :modal_delete, :modal_refus_suspension]

  def edit; end

  def update
    if @suspension.update(suspension_params)
      @acte.update!(etat: "en cours d'instruction")
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @suspension.destroy
    redirect_to edit_ht2_acte_path(@acte, etape: 3)
  end

  def refus_suspension
    @suspension.destroy
    @acte.update!(
      etat: "en cours d'instruction",
      renvoie_instruction: true,
      commentaire_proposition_decision: params[:ht2_acte][:commentaire_proposition_decision]
    )
    redirect_to ht2_acte_path(@acte), notice: "Acte renvoyé en instruction."
  end

  def modal_delete; end

  def modal_refus_suspension; end

  private

  def suspension_params
    params.require(:suspension).permit(:date_suspension, :motif, :observations, :date_reprise, :commentaire_reprise)
  end

  def set_suspension
    id = params[:id] || params[:suspension_id]
    @suspension = Suspension.find(id)
  end

  def set_acte
    @acte = @suspension.ht2_acte
  end
end
