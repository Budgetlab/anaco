class GestionSchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_unless_dcb, only: [:new, :create, :edit, :update]
  before_action :set_gestion_schema, only: [:edit, :update]
  before_action :set_schema, only: [:new, :create, :edit, :update]
  before_action :redirect_if_schema_complete, only: [:new, :create, :edit, :update]

  def new
    @programme = @schema.programme
    # identifier formulaire et remplissage par défaut en fonction du statut (retours gérés dans edit)
    @step = @schema.statut.to_i
    if @step == 1 || @step == 3
      # vision RPROG : prendre les données du schema précédent (valide) s'il existe
      previous_schema = @programme.last_schema_valid
      if previous_schema
        gestion_schema_previous = previous_schema.gestion_schemas.where(vision: 'RPROG', profil: @step == 1 ? 'HT2' : 'T2').first
        @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
      else
        @gestion_schema = @schema.gestion_schemas.new
      end

    elsif @step == 2 || @step == 4
      # vision CBCM : on récupère les données de la vision RPROG précédente
      gestion_schema_previous = @schema.last_gestion_schema
      @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
    end
  end

  def create
    @gestion_schema = @schema.gestion_schemas.new(gestion_schema_params.merge(programme_id: @schema.programme_id, user_id: current_user.id, annee: Date.today.year))
    assign_vision_profil
    @gestion_schema.save
    # mettre à jour l'etape dans le statut du schema
    steps_max = @schema.programme.dotation == 'HT2' ? 2 : 4
    statut = @schema.statut.to_i + 1 > steps_max ? 'valide' : (@schema.statut.to_i + 1).to_s
    @schema.update(statut: statut)
    next_path = statut == 'valide' ? schemas_path : new_schema_gestion_schema_path(@schema)
    redirect_to next_path
  end

  def edit
    # possibilité de revenir en arrière et modifier gestion schema
    @programme = @gestion_schema.programme
    @edit = true
    @step = if @gestion_schema.profil == 'HT2'
              @gestion_schema.vision == 'RPROG' ? 1 : 2
            else
              @gestion_schema.vision == 'RPROG' ? 3 : 4
            end
  end

  def update
    @gestion_schema.update(gestion_schema_params)
    # redirection en fonction de l'étape
    if @gestion_schema.vision == 'RPROG'
      gestion_schema_next = @schema.gestion_schemas.where(vision: 'CBCM', profil: @gestion_schema.profil)&.first
    elsif @gestion_schema.vision == 'CBCM'
      # edit ne peux survenir que sur le CBCM HT2 car T2 toujours dernière étape avant sauvegarde finale
      gestion_schema_next = @schema.gestion_schemas.where(vision: 'RPROG', profil: 'T2')&.first
    end
    # si gestion schema d'après existe on retourne sur edit sinon on repart de new
    next_path = gestion_schema_next ? edit_schema_gestion_schema_path(gestion_schema_next, schema_id: @schema.id) : new_schema_gestion_schema_path(@schema)
    redirect_to next_path
  end

  private

  def gestion_schema_params
    params.require(:gestion_schema).permit(:user_id, :programme_id, :vision, :profil, :annee,
                                           :ressources_ae, :ressources_cp, :depenses_ae, :depenses_cp,
                                           :mer_ae, :mer_cp,  :surgel_ae, :surgel_cp, :mobilisation_mer_ae,
                                           :mobilisation_mer_cp,:mobilisation_surgel_ae, :mobilisation_surgel_cp,
                                           :fongibilite_ae, :fongibilite_cp, :decret_ae, :decret_cp,
                                           :credits_lfg_ae, :credits_lfg_cp, :reports_ae, :reports_cp,
                                           :charges_a_payer_ae, :charges_a_payer_cp, :credits_reports_ae,
                                           :credits_reports_cp,:credits_reports_autre_ae, :credits_reports_autre_cp,
                                           :reports_autre_ae, :reports_autre_cp, :commentaire, transferts_attributes: [:_destroy, :nature, :montant_ae, :montant_cp, :programme_id])
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
    redirect_to schemas_remplissage_path if @schema&.complete?
  end


  def assign_vision_profil
    vision = %w[RPROG CBCM RPROG CBCM]
    profil = %w[HT2 HT2 T2 T2]
    @step = @schema.statut.to_i - 1
    @gestion_schema.vision = vision[@step]
    @gestion_schema.profil = profil[@step]
  end
end
