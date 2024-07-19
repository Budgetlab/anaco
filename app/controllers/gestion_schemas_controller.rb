class GestionSchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_unless_dcb, only: [:new, :create, :edit, :update, :destroy, :suivi_remplissage]
  before_action :set_gestion_schema, only: [:edit, :update, :destroy]

  # Historique des schema fin de gestion
  def index
    @gestion_schemas = current_user.statut == 'DCB' ? current_user.gestion_schemas : GestionSchema.all
    @gestion_schemas = @gestion_schemas.order(created_at: :desc)
    @q = @gestion_schemas.ransack(params[:q])
    @gestion_schemas = @q.result.includes(:programme, :user)
    @pagy, @gestion_schemas_page = pagy(@gestion_schemas)
  end



  def new
    @programme = Programme.find(params[:programme_id])
    @gestion_schema = @programme.gestion_schemas.new
  end

  def create
    @programme = Programme.find(params[:programme_id])
    schema = Schema.create(user_id: current_user.id, programme_id: @programme.id, statut: "Brouillon", annee: Date.today.year)
    @gestion_schema = current_user.gestion_schemas.new(gestion_schema_params.merge(programme_id: @programme.id, schema_id: schema.id, annee: Date.today.year))
    @gestion_schema.save
    redirect_to gestion_schemas_path
  end

  def edit
    @programme = @gestion_schema.programme
  end

  def destroy
    @gestion_schema&.destroy
    redirect_to gestion_schemas_path
  end

  private

  def gestion_schema_params
    params.require(:gestion_schema).permit(:user_id, :programme_id, :vision, :profil, :annee,
                                           :prevision_solde_budgetaire_ae, :prevision_solde_budgetaire_cp,
                                           :mer_ae, :mer_cp, :mobilisation_mer_ae, :mobilisation_mer_cp,
                                           :fongibilite_ae, :fongibilite_cp, :decret_ae, :decret_cp,
                                           :credits_ouverts_ae, :credits_ouverts_cp, :charges_a_payer_ae,
                                           :charges_a_payer_cp, :credits_reports_ae, :credits_reports_cp,
                                           :reports_autre_ae, :reports_autre_cp, :commentaire)
  end

  def set_gestion_schema
    @gestion_schema = GestionSchema.find(params[:id])
  end

  def redirect_unless_dcb
    redirect_to root_path unless current_user.statut == 'DCB'
  end
end
