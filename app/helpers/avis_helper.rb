module AvisHelper

  def badge_class_for_etat(etat)
    case etat
    when 'En attente de lecture'
      'fr-badge fr-badge--purple-glycine'
    when 'Lu'
      'fr-badge fr-badge--info fr-badge--no-icon'
    when 'Brouillon'
      'fr-badge fr-badge--new fr-badge--no-icon'
    else
      'fr-badge'
    end
  end

  def badge_class_for_statut(statut)
    case statut
    when 'Favorable', 'Aucun risque'
      'fr-badge fr-badge--success'
    when 'Favorable avec réserve', 'Risques éventuels ou modérés', 'Risques modérés'
      'fr-badge fr-badge--warning'
    when 'Défavorable', 'Risques certains ou significatifs', 'Risques significatifs'
      'fr-badge fr-badge--error'
    else
      'fr-badge'
    end
  end

  def get_avis_for_bop(phases, bop, avis)
    phases.map do |phase|
      avis.find { |a| a.bop_id == bop.id && a.phase == phase }
    end
  end

  # fonction pour afficher la répartition des statuts pour les avis début de gestion de l'année sélectionnée
  def avis_repartition(avis, avis_total, phase)
    avis = avis.where(phase: phase).select('DISTINCT ON (bop_id) avis.*').order('bop_id, avis.created_at DESC') if phase == 'services votés'
    avis_favorables = avis.count { |a| a.statut == 'Favorable' && a.phase == phase }
    avis_reserves = avis.count { |a| a.statut == 'Favorable avec réserve' && a.phase == phase }
    avis_defavorables = avis.count { |a| a.statut == 'Défavorable' && a.phase == phase }
    avis_vide = avis_total - avis_favorables - avis_reserves - avis_defavorables
    [avis_favorables, avis_reserves, avis_defavorables, avis_vide]
  end

  # fonction pour afficher la répartition des dates de réception pour les avis début de gestion de l'année sélectionnée
  def avis_date_repartition(avis, avis_total, annee, phase)
    avis = avis.where(phase: phase).select('DISTINCT ON (bop_id) avis.*').order('bop_id, avis.created_at DESC') if phase == 'services votés'
    avis_date_1 = avis.count { |a| !a.date_reception.nil? && a.date_reception <= Date.new(annee, 3, 1) && a.phase == phase }
    avis_date_2 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 1) && a.date_reception <= Date.new(annee, 3, 15) && a.phase == phase }
    avis_date_3 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 15) && a.date_reception <= Date.new(annee, 3, 31) && a.phase == phase }
    avis_date_4 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 4, 1) && a.phase == phase }
    avis_vide = avis_total - avis_date_1 - avis_date_2 - avis_date_3 - avis_date_4
    [avis_date_1, avis_date_2, avis_date_3, avis_date_4, avis_vide]
  end

  # fonction pour afficher les graphes avec la répartition des statuts pour les notes CRG1 et CRG2
  def notes_repartition(avis, avis_total, phase)
    notes_counts = avis.select { |a| a.phase == phase }.group_by(&:statut).transform_values(&:count)
    notes_sans_risque = notes_counts['Aucun risque'].to_i
    notes_moyen = (notes_counts['Risques éventuels ou modérés'] || 0) + (notes_counts['Risques modérés'] || 0)
    notes_red = (notes_counts['Risques certains ou significatifs'] || 0) + (notes_counts['Risques significatifs'] || 0)
    notes_vide = avis_total - notes_sans_risque - notes_moyen - notes_red
    [notes_sans_risque, notes_moyen, notes_red, notes_vide]
  end

  # fonction pour calculer le nombre d'avis avec CRG1 prévu parmi la liste des avis remplis sur l'année
  def avis_crg1(avis)
    avis.count { |a| a.is_crg1 && a.phase == 'début de gestion' }
  end

  # fonction pour calculer le nombre d'avis données sans interruption du delai parmi la liste des avis remplis
  def avis_delai(avis)
    avis.count { |a| !a.is_delai && a.phase == 'début de gestion' }
  end

  # fonction pour charger les avis renseignés dans l'année en cours (hors avis d'éxécution et brouillon)
  def avis_annee_remplis(annee)
    Avi.where(annee: annee).where.not(etat: 'Brouillon').where.not(phase: 'execution')
  end

  def avis_remplis_phase(avis, phase)
    avis.select { |a| a.phase == phase && a.statut != 'Brouillon' }.count
  end

  def avis_brouillon_phase(avis, phase)
    avis.select { |a| a.phase == phase && a.statut == 'Brouillon' }.count
  end

  def avis_a_remplir(avis, phase, annee)
    case phase
    when 'CRG1'
      avis.select { |a| a.phase == 'début de gestion' && a.is_crg1? && a.statut != 'Brouillon' }.count
    else
      Bop.all.where('created_at <= ?', Date.new(annee, 12, 31)).where.not(dotation: 'aucune').count
    end
  end

  def taux_remplissage_avis(avis, phase, annee)
    if avis_a_remplir(avis, phase, annee).zero?
      100
    else
      (avis_remplis_phase(avis, phase) * 100.0 / avis_a_remplir(avis, phase, annee)).to_f.round
    end
  end

  def avis_lus(avis, phase)
    avis.joins(:user).where('user.statut': 'CBR').select { |a| a.phase == phase && a.etat == 'Lu' }.count
  end

  def avis_recus(avis, phase)
    avis.joins(:user).where('user.statut': 'CBR').select { |a| a.phase == phase && a.etat != 'Brouillon' }.count
  end

  def taux_lecture_avis(avis, phase)
    if avis_recus(avis, phase).zero?
      100
    else
      (avis_lus(avis, phase) * 100.0 / avis_recus(avis, phase)).to_f.round
    end
  end

  # Method to get the number of the avis based on its creation date
  def numero_avis_services_votes(avis, avis_all)
    avis_services_votes = avis_all.select { |a| a.phase == 'services votés' && a.annee == avis.annee && a.bop_id == avis.bop_id }
                                  .sort_by(&:created_at)
    avis_services_votes.index(avis) + 1
  end

end
