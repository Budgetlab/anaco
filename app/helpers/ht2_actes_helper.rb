module Ht2ActesHelper
  def badge_class_for_decision(decision)
    case decision
    when 'Favorable'
      'fr-badge fr-badge--success fr-badge--no-icon'
    when 'Favorable avec observations'
      'fr-badge fr-badge--green-menthe'
    when 'Défavorable'
      'fr-badge fr-badge--error fr-badge--no-icon'
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
    else
      'crouge'
    end
  end
end
