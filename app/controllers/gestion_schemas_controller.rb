class GestionSchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_unless_dcb, only: [:new, :create, :edit, :update, :destroy, :suivi_remplissage]
  before_action :set_gestion_schema, only: [:edit, :update, :destroy]
  before_action :set_schema, only: [:new, :create]
  before_action :redirect_if_schema_complete, only: [:new, :create]
  before_action :redirect_if_gestion_schema_brouillon, only: [:new]

  # Historique des schemas fin de gestion
  def index
    # Récupère les "gestion_schemas" en fonction du statut de l'utilisateur, puis les trie par date de création.
    @gestion_schemas = current_user.statut == 'DCB' ? current_user.gestion_schemas : GestionSchema.all
    @gestion_schemas = @gestion_schemas.order(created_at: :desc)
    # Crée un objet de recherche avec Ransack, effectue la recherche et inclut les associations liées.
    @q = @gestion_schemas.ransack(params[:q])
    @gestion_schemas = @q.result.includes(:programme, :user)
    # Met en place la pagination avec Pagy.
    @pagy, @gestion_schemas_page = pagy(@gestion_schemas)
  end

  def new
    @programme = @schema.programme
    if @schema.statut == '1' || @schema.statut == '3'
      # prendre les données du schema précédent (valide) s'il existe
      previous_schema = @schema.programme.schemas&.where(annee: Date.today.year, statut: 'valide')&.order(created_at: :desc)&.first
      if previous_schema
        gestion_schema_previous = previous_schema&.gestion_schemas.offset(@schema.statut.to_i - 1)
        @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
      else
        @gestion_schema = @schema.gestion_schemas.new
      end

    elsif @schema.statut == '2' || @schema.statut == '4'
      # si vision RPROG on récupérer les données de la vision CBCM précédente
      gestion_schema_previous = @schema.gestion_schemas.order(created_at: :desc).first
      @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
    end
  end

  def create
    @gestion_schema = @schema.gestion_schemas.new(gestion_schema_params.merge(programme_id: @schema.programme_id, user_id: current_user.id, annee: Date.today.year, statut: 'valide'))
    assign_vision_profil
    @gestion_schema.save
    # mettre à jour l'etape dans le statut du schema
    steps_max = @schema.programme.dotation == 'HT2 et T2' ? 4 : 2
    statut = @schema.statut.to_i + 1 > steps_max ? 'valide' : (@schema.statut.to_i + 1).to_s
    @schema.update(statut: statut)
    redirect_to new_schema_gestion_schema_path(@schema)
  end

  def edit
    @programme = @gestion_schema.programme
  end

  def update
    @gestion_schema.update(gestion_schema_params)
    redirect_to new_schema_gestion_schema_path(@schema)
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

  def set_schema
    @schema = Schema.find(params[:schema_id])
  end

  def redirect_unless_dcb
    redirect_to root_path unless current_user.statut == 'DCB'
  end

  def redirect_if_schema_complete
    redirect_to schemas_suivi_path if @schema&.complete?
  end

  def redirect_if_gestion_schema_brouillon
    last_gestion_schema = @schema.gestion_schemas&.order(created_at: :desc)&.first
    redirect_to edit_gestion_schema_path(last_gestion_schema) and return if last_gestion_schema && last_gestion_schema&.statut != 'valide'
  end

  def assign_vision_profil
    vision = ["RPROG", "CBCM", "RPROG", "CBCM"]
    profil = ["HT2", "HT2", "T2", "T2"]
    @step = @schema.statut.to_i - 1
    @gestion_schema.vision = vision[@step]
    @gestion_schema.profil = profil[@step]
  end
end
