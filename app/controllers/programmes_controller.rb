# frozen_string_literal: true

# controller Programme
class ProgrammesController < ApplicationController
  before_action :authenticate_user!
  require 'axlsx'
  include ApplicationHelper
  # Page liste des crédits non repartis par programme
  def index
    redirect_to root_path if current_user.statut != 'DCB'

    @annee_a_afficher = annee_a_afficher
    @programmes = current_user.programmes
    @liste_credits_par_programme = @programmes.joins(:credits).where('credits.annee': @annee_a_afficher).pluck(:id, 'credits.etat AS credit_etat', 'credits.phase AS credit_phase', 'credits.is_crg1 AS credit_crg1')
    count_reste_index(@annee_a_afficher)
  end

  # Page pour importer le fichier des programmes
  def new
    redirect_to root_path if current_user.statut != 'admin'
  end

  def import
    Programme.import(params[:file])
    respond_to do |format|
      format.turbo_stream { redirect_to new_programme_path }
    end
  end

  private

  def count_reste_index(annee)
    phase = annee == @annee ? @phase : 'CRG2'
    @count_reste = case phase
                   when 'début de gestion'
                     @programmes.length - @liste_credits_par_programme.count { |el| el[1] != 'Brouillon' }
                   when 'CRG1'
                     @programmes.length + @liste_credits_par_programme.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_credits_par_programme.count { |el| el[1] != 'Brouillon' }
                   when 'CRG2'
                     2 * @programmes.length + @liste_credits_par_programme.count { |el| el[1] != 'Brouillon' && el[2] == 'début de gestion' && el[3] == true } - @liste_credits_par_programme.count { |el| el[1] != 'Brouillon' }
                   end
    liste_credits_annee_precedente = current_user.credits.where(annee: annee - 1)
    liste_credit_annee_precedente_debut = liste_credits_annee_precedente.count { |credit| credit.phase == 'début de gestion' && credit.etat != 'Brouillon' }
    liste_credit_annee_precedente_crg2 = liste_credits_annee_precedente.count { |credit| credit.phase == 'CRG2' && credit.etat != 'Brouillon' }
    @count_reste_annee_precedente = liste_credit_annee_precedente_debut - liste_credit_annee_precedente_crg2
  end
end
