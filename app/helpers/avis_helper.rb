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
end
