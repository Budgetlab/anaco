class SchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_schema, only: [:destroy, :show, :confirm_delete]
  before_action :set_programme, only: [:create]
  before_action :retrieve_last_schema_and_redirect_if_incomplete, only: [:create]
  def index
    # récupérer la liste des schémas triés par ordre croissant
    @schemas = current_user.statut == 'DCB' ? current_user.schemas.joins(:gestion_schemas).distinct : Schema.where(statut: 'valide')
    @schemas = @schemas.order(created_at: :desc)
    # recherche filtres ransack
    @q = @schemas.ransack(params[:q])
    @schemas = @q.result.includes(:programme, :user)
    # paginger les résultats
    @pagy, @schemas_page = pagy(@schemas)
  end

  def create
    # démarrer direct à l'étape 3 si doté uniquement en T2
    @statut = @programme.dotation == 'T2' ? '3' : '1'
    @schema = @programme.schemas.create(user_id: @programme.user_id, annee: Date.today.year, statut: @statut)

    redirect_to new_schema_gestion_schema_path(@schema)
  end

  # suivi remplissage des schémas par programme pour les DCB
  def schemas_remplissage
    @programmes = current_user.programmes.order(numero: :asc)
  end

  def show
    @vision_rprog_ht2 = @schema.gestion_schemas.find_by(vision: 'RPROG', profil: 'HT2')
    @vision_rprog_t2 = @schema.gestion_schemas.find_by(vision: 'RPROG', profil: 'T2')
    @vision_cbcm_ht2 = @schema.gestion_schemas.find_by(vision: 'CBCM', profil: 'HT2')
    @vision_cbcm_t2 = @schema.gestion_schemas.find_by(vision: 'CBCM', profil: 'T2')
  end

  def destroy
    @schema&.destroy
    redirect_to schemas_path
  end

  def confirm_delete; end

  private

  def set_schema
    @schema = Schema.find(params[:id])
  end

  def set_programme
    @programme = Programme.find(params[:programme_id])
  end

  def retrieve_last_schema_and_redirect_if_incomplete
    last_schema = @programme.schemas&.where(annee: Date.today.year)&.order(created_at: :desc)&.first
    redirect_to new_schema_gestion_schema_path(@schema) and return if last_schema&.incomplete?
  end
end
