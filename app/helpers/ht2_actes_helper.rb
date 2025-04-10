module Ht2ActesHelper
  def badge_class_for_decision(decision)
    case decision
    when 'Favorable', 'Visa accordé'
      'fr-badge fr-badge--success fr-badge--no-icon'
    when 'Favorable avec observations', 'Visa accordé avec observations'
      'fr-badge fr-badge--green-menthe'
    when 'Défavorable', 'Refus de visa'
      'fr-badge fr-badge--error fr-badge--no-icon'
    when 'Saisine a posteriori'
      'fr-badge fr-badge--beige-gris-galet'
    else
      'fr-badge'
    end
  end

  def badge_class_for_type(type_acte)
    case type_acte
    when 'avis'
      'fr-badge fr-badge--green-archipel'
    when 'visa'
      'fr-badge fr-badge--beige-gris-galet'
    when 'TF'
      'fr-badge fr-badge--pink-tuile'
    else
      'fr-badge'
    end
  end

  def badge_class_for_etat_actes(etat)
    case etat
    when 'en pré-instruction'
      "fr-badge fr-badge--warning fr-badge--no-icon"
    when "en cours d'instruction"
      'fr-badge fr-badge--green-archipel'
    when 'suspendu'
      'fr-badge fr-badge--error fr-badge--no-icon'
    when 'en attente de validation'
      'fr-badge fr-badge--pink-tuile'
    else
      'fr-badge'
    end
  end

  def flag_date(date_limite)
    return '' unless date_limite # Protection contre les valeurs nil

    case
    when date_limite > Date.today + 10.days
      'cgreen'
    when date_limite > Date.today + 5.days
      'cwarning'
    when date_limite >= Date.today
      'crouge'
    else
      'cblack'
    end
  end
end
