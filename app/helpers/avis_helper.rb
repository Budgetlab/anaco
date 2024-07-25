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
      'fr-badge fr-badge--new'
    when 'Défavorable', 'Risques certains ou significatifs', 'Risques significatifs'
      'fr-badge fr-badge--warning'
    else
      'fr-badge'
    end
  end

  def get_avis_for_bop(phases, bop, avis)
    phases.map do |phase|
      avis.find { |a| a.bop_id == bop.id && a.phase == phase }
    end
  end

end
