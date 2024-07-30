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
  def avis_repartition(avis, avis_total)
    avis_favorables = avis.count { |a| a.statut == 'Favorable' && a.phase == 'début de gestion' }
    avis_reserves = avis.count { |a| a.statut == 'Favorable avec réserve' && a.phase == 'début de gestion' }
    avis_defavorables = avis.count { |a| a.statut == 'Défavorable' && a.phase == 'début de gestion' }
    avis_vide = avis_total - avis_favorables - avis_reserves - avis_defavorables
    [avis_favorables, avis_reserves, avis_defavorables, avis_vide]
  end

  # fonction pour afficher la répartition des dates de réception pour les avis début de gestion de l'année sélectionnée
  def avis_date_repartition(avis, avis_total, annee)
    avis_date_1 = avis.count { |a| !a.date_reception.nil? && a.date_reception <= Date.new(annee, 3, 1) && a.phase == 'début de gestion' }
    avis_date_2 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 1) && a.date_reception <= Date.new(annee, 3, 15) && a.phase == 'début de gestion' }
    avis_date_3 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 15) && a.date_reception <= Date.new(annee, 3, 31) && a.phase == 'début de gestion' }
    avis_date_4 = avis.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 4, 1) && a.phase == 'début de gestion' }
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

end
