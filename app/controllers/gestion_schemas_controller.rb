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
    @vision = @step == 1 || @step == 3 ? 'RPROG' : 'CBCM'
    @profil = @step == 1 || @step == 2 ? 'HT2' : 'T2'
    # si brouillon rediriger vers edit
    redirect_to edit_schema_gestion_schema_path(@schema.gestion_schemas.where(vision: @vision, profil: @profil).first, schema_id: @schema.id) and return if @schema&.gestion_schemas&.where(vision: @vision, profil: @profil)&.first

    previous_schema = @programme.last_schema_valid
    # si version > 1 récupérer les données des versions précedentes sur le même profil
    if previous_schema
      gestion_schema_previous = previous_schema.gestion_schemas.where(vision: @vision, profil: @profil).first
      @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
      transferts_attributes = gestion_schema_previous.transferts.map do |transfert|
        transfert.attributes.except('id')
      end
      @gestion_schema.transferts.build(transferts_attributes)
      @edit = true # récupérer les commentaires
    else
      # vision CBCM : on récupère les données de la vision RPROG précédente
      if @step == 2 || @step == 4
        # vision CBCM : on récupère les données de la vision RPROG précédente
        gestion_schema_previous = @schema.last_gestion_schema
        @gestion_schema = @schema.gestion_schemas.new(gestion_schema_previous.attributes)
      else
        @gestion_schema = @schema.gestion_schemas.new
      end
    end
  end

  def create
    @gestion_schema = @schema.gestion_schemas.new(gestion_schema_params.merge(programme_id: @schema.programme_id, user_id: current_user.id, annee: Date.today.year))
    assign_vision_profil
    @gestion_schema.save
    # si quitte formulaire
    if params[:brouillon]
      next_path = schemas_path
    else
      # mettre à jour l'etape dans le statut du schema
      steps_max = @schema.programme.dotation == 'HT2' ? 2 : 4
      statut = @schema.statut.to_i + 1 > steps_max ? 'valide' : (@schema.statut.to_i + 1).to_s
      @schema.update(statut: statut)
      next_path = statut == 'valide' ? schemas_path : new_schema_gestion_schema_path(@schema)
    end
    redirect_to next_path
  end

  def edit
    # possibilité de revenir en arrière et modifier gestion schema
    @programme = @gestion_schema.programme
    @edit = true
    @step = @gestion_schema.step
    @vision = @step == 1 || @step == 3 ? 'RPROG' : 'CBCM'
  end

  def update
    @gestion_schema.transferts.destroy_all
    @gestion_schema.update(gestion_schema_params)
    # si enregistre en brouillon
    if params[:brouillon]
      next_path = schemas_path
    else
      @step = @gestion_schema.step
      # redirection en fonction de l'étape
      if @step == 1 || @step == 3 # vision RPROG, on va sur la vision CBCM du meme profil
        gestion_schema_next = @schema.gestion_schemas.where(vision: 'CBCM', profil: @gestion_schema.profil)&.first
      elsif @step == 2
        # edit ne peux survenir que sur le CBCM HT2 car T2 toujours dernière étape avant sauvegarde finale
        gestion_schema_next = @schema.gestion_schemas.rprog_t2&.first
      end
      # si gestion schema d'après n'existe pas on met à jour statut du schema par validation pour passer à l'étape suivante
      unless gestion_schema_next
        steps_max = @schema.programme.dotation == 'HT2' ? 2 : 4
        statut = @step + 1 > steps_max ? 'valide' : (@step + 1).to_s
        @schema.update(statut: statut)
        next_path_new = statut == 'valide' ? schemas_path : new_schema_gestion_schema_path(@schema)
      end
      # si gestion schema d'après existe on retourne sur edit sinon on repart de new ou termine process si dernière étape
      next_path = gestion_schema_next ? edit_schema_gestion_schema_path(gestion_schema_next, schema_id: @schema.id) : next_path_new
    end
    redirect_to next_path
  end

  private

  def gestion_schema_params
    params.require(:gestion_schema).permit(:user_id, :programme_id, :vision, :profil, :annee,
                                           :ressources_ae, :ressources_cp, :depenses_ae, :depenses_cp,
                                           :mer_ae, :mer_cp, :surgel_ae, :surgel_cp, :mobilisation_mer_ae,
                                           :mobilisation_mer_cp, :mobilisation_surgel_ae, :mobilisation_surgel_cp,
                                           :fongibilite_ae, :fongibilite_cp, :decret_ae, :decret_cp,
                                           :credits_lfg_ae, :credits_lfg_cp, :reports_ae, :reports_cp,
                                           :charges_a_payer_ae, :charges_a_payer_cp, :credits_reports_ae,
                                           :credits_reports_cp, :credits_reports_autre_ae, :credits_reports_autre_cp,
                                           :reports_autre_ae, :reports_autre_cp, :commentaire, :fongibilite_hcas,
                                           :fongibilite_cas, transferts_attributes: [:_destroy, :nature, :montant_ae, :montant_cp, :programme_id])
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
