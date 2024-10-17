class SchemasController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_dcb_or_admin!, except: [:pdf_vision, :show]
  before_action :set_schema, only: [:destroy, :show, :confirm_delete, :pdf_vision]
  before_action :set_programme, only: [:create]
  before_action :retrieve_last_schema_and_redirect_if_incomplete, only: [:create]
  include ApplicationHelper
  include GestionSchemasHelper

  def index
    # récupérer la liste des schémas triés par ordre croissant
    @schemas = current_user.statut == 'DCB' ? current_user.schemas.joins(:gestion_schemas).distinct : Schema.where(statut: 'valide')
    @schemas = @schemas.order(updated_at: :desc)
    # recherche filtres ransack
    @q = @schemas.ransack(params[:q])
    @schemas = @q.result.includes(:programme, :user, gestion_schemas: :transferts)
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
    @programmes = current_user.programmes.where(statut: 'Actif').order(numero: :asc)
  end

  def show
    @gestion_schemas = @schema.gestion_schemas.includes(transferts: :programme)
    filename = "Schema_fin_de_gestion_P#{@schema.programme.numero}.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" }
    end
  end

  def destroy
    @schema&.destroy
    redirect_to schemas_path
  end

  def confirm_delete; end

  def pdf_vision
    @gestion_schemas = @schema.gestion_schemas.includes(transferts: :programme)

    respond_to do |format|
      format.html
      format.pdf do
        if @schema.document_pdf.attached? # vérifiez si un pdf est attaché
          send_data(
            @schema.document_pdf.download, # envoyez le pdf attaché
            filename: @schema.document_pdf.filename.to_s,
            type: "application/pdf",
            disposition: "attachment"
          )
        else
          url = pdf_vision_schema_url(@schema)
          tmp_path = UrlToPdfJob.perform_now(url)
          # envoyer le pdf en réponse
          pdf_data = File.read(tmp_path)
          send_data(pdf_data,
                    filename: "schema_P#{@schema.programme.numero}.pdf",
                    type: "application/pdf",
                    disposition: "attachment") # inline open in browser
          # disposition: "attachment") # default # download
          # ouvrir le fichier temporaire et attacher au modèle Schema
          File.open(tmp_path) do |file|
            @schema.document_pdf.attach(io: file, filename: "schema_P#{@schema.programme.numero}.pdf")
          end

          # assurez-vous de supprimer le fichier temporaire après son utilisation
          File.delete(tmp_path)
        end
      end
    end
  end

  private

  def set_schema
    @schema = Schema.includes(:programme).find(params[:id])
  end

  def set_programme
    @programme = Programme.find(params[:programme_id])
  end

  def retrieve_last_schema_and_redirect_if_incomplete
    last_schema = @programme.schemas&.where(annee: Date.today.year)&.order(created_at: :desc)&.first
    redirect_to new_schema_gestion_schema_path(@schema) and return if last_schema&.incomplete?
  end
end
