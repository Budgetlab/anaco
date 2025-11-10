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
      'fr-badge fr-badge--new fr-badge--no-icon'
    when "en cours d'instruction"
      'fr-badge fr-badge--green-archipel'
    when 'suspendu'
      'fr-badge fr-badge--error fr-badge--no-icon'
    when 'à valider'
      'fr-badge fr-badge--pink-tuile'
    when 'clôturé'
      'fr-badge fr-badge--success fr-badge--no-icon'
    when 'clôturé après pré-instruction'
      'fr-badge fr-badge--yellow-tournesol'
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

  def update_acte_notice(etat, etape)
    if etat == 'à valider'
      "Acte enregistré et en attente de validation."
    elsif etat == 'clôturé'
      "Acte clôturé avec succès."
    elsif etat == 'à clôturer'
      "Acte validé avec succès. Il doit désormais être clôturé par l'instructeur."
    elsif etat == 'suspendu'
      "Acte suspendu."
    elsif etat == 'à suspendre'
      "Acte à suspendre par le valideur."
    elsif etat == "clôturé après pré-instruction"
      "Acte clôturé après pré-instruction avec succès."
    elsif etape == 7
      "Acte renvoyé en pré-instruction avec succès."
    elsif etape == 8
      "Acte renvoyé en instruction avec succès."
    else
      "Acte enregistré et mis à jour avec succès."
    end
  end
end
