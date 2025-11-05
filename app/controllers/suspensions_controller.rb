class SuspensionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_suspension, only: [:edit, :update, :destroy]

  def edit
    @acte = @suspension.ht2_acte
  end

  def update
    @acte = @suspension.ht2_acte
    if @suspension.update(suspension_params)
      @acte.update!(etat: "en cours d'instruction")
      redirect_to edit_ht2_acte_path(@acte, etape: 2)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  private

  def suspension_params
    params.require(:suspension).permit(:date_suspension, :motif, :observations, :date_reprise)
  end

  def set_suspension
    @suspension = Suspension.find(params[:id])
  end
end
