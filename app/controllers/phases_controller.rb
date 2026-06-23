# frozen_string_literal: true

# Gestion du calendrier des phases de saisie des avis (admin uniquement).
class PhasesController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!

  # Onglets par année. Affiche toutes les années qui ont au moins une phase
  # définie, plus l'année courante si absente (pour permettre de l'initialiser).
  def index
    @phases_par_annee = Phase.order(:annee, :date_debut).group_by(&:annee)
    annees_dispos = (@phases_par_annee.keys + [Date.today.year]).uniq.sort.reverse
    @annees_dispos = annees_dispos
    @annee_active  = params[:annee].to_i if params[:annee].present?
    @annee_active  = Date.today.year unless annees_dispos.include?(@annee_active)
  end

  def create
    annee_demandee = phase_params[:annee].to_i
    if annee_demandee != Date.today.year
      redirect_to phases_path(annee: annee_demandee),
                  alert: "L'ajout d'une phase n'est possible que pour l'année en cours (#{Date.today.year})." and return
    end

    @phase = Phase.new(phase_params)
    if @phase.save
      redirect_to phases_path(annee: @phase.annee),
                  notice: "Phase « #{@phase.libelle_avec_numero} » ajoutée pour #{@phase.annee}."
    else
      redirect_to phases_path(annee: annee_demandee),
                  alert: "Impossible d'ajouter la phase : #{@phase.errors.full_messages.to_sentence}"
    end
  end

  def update
    @phase = Phase.find(params[:id])
    if @phase.annee != Date.today.year
      redirect_to phases_path(annee: @phase.annee),
                  alert: "La modification n'est possible que pour les phases de l'année en cours (#{Date.today.year})." and return
    end

    if @phase.update(phase_params)
      redirect_to phases_path(annee: @phase.annee),
                  notice: "Date de début de « #{@phase.libelle_avec_numero} » mise à jour."
    else
      redirect_to phases_path(annee: @phase.annee),
                  alert: "Impossible de mettre à jour : #{@phase.errors.full_messages.to_sentence}"
    end
  end

  # Suppression interdite :
  # - sur les années passées (pour ne pas casser l'historique du calendrier)
  # - si la phase est référencée par au moins un avis (garde-fou contre la perte
  #   de données métier — `has_many :avis, dependent: :nullify` n'est pas déclenché).
  def destroy
    @phase = Phase.find(params[:id])
    annee  = @phase.annee

    if annee != Date.today.year
      redirect_to phases_path(annee: annee),
                  alert: "La suppression n'est possible que pour les phases de l'année en cours (#{Date.today.year})." and return
    end

    if @phase.avis.exists?
      redirect_to phases_path(annee: annee),
                  alert: "Impossible de supprimer : #{@phase.avis.count} avis y sont rattachés." and return
    end
    libelle = @phase.libelle_avec_numero
    @phase.destroy
    redirect_to phases_path(annee: annee), notice: "Phase « #{libelle} » supprimée."
  end

  private

  def phase_params
    params.require(:phase).permit(:nom, :annee, :date_debut)
  end
end
