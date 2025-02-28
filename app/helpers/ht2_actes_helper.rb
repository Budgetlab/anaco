module Ht2ActesHelper
  def badge_class_for_decision(decision)
    case decision
    when 'Favorable'
      'fr-badge fr-badge--success fr-badge--no-icon'
    when 'Favorable avec observation'
      'fr-badge fr-badge--green-menthe'
    when 'Défavorable'
      'fr-badge fr-badge--error fr-badge--no-icon'
    else
      'fr-badge'
    end
  end
end
