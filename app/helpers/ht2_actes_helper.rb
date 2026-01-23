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
    when 'suspendu', 'à suspendre'
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

  def etat_acte(acte)
    if acte.etat == 'suspendu' && (acte.type_acte == 'visa' || acte.type_acte == 'TF')
      'interrompu'
    elsif acte.etat == 'à suspendre' && (acte.type_acte == 'visa') && (acte.type_acte == 'visa' || acte.type_acte == 'TF')
      "à interrompre"
    else
      acte.etat
    end
  end

  def type_suspension(acte)
    acte.type_acte == 'avis' ? 'suspension' : 'interruption'
  end

  def verbe_suspension(acte)
    acte.type_acte == 'avis' ? 'suspendre' : 'interrompre'
  end

  def update_acte_notice(etat, etape, type_acte)
    if etat == 'à valider'
      "Acte enregistré et en attente de validation."
    elsif etat == 'clôturé'
      "Acte clôturé avec succès."
    elsif etat == 'à clôturer'
      "Acte validé avec succès. Il doit désormais être clôturé par l'instructeur."
    elsif etat == 'suspendu' && type_acte == 'avis'
      "Acte suspendu."
    elsif etat == 'suspendu' && type_acte != 'avis'
      "Acte interrompu."
    elsif etat == 'à suspendre' && type_acte == 'avis'
      "Acte à suspendre par le valideur."
    elsif etat == 'à suspendre' && type_acte != 'avis'
      "Acte à interrompre par le valideur."
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

  def tous_types_observations
    [
      "Acte déjà signé par l'ordonnateur",
      "Acte non soumis au contrôle",
      'Compatibilité avec la programmation',
      "Construction de l'EJ",
      'Disponibilité des crédits',
      'Évaluation de la consommation des crédits',
      'Fondement juridique',
      "Hors périmètre du CBR/DCB",
      'Imputation',
      'Pièce(s) manquante(s)',
      "Problème dans la rédaction de l'acte",
      'Risque au titre de la RGP',
      'Saisine a posteriori',
      'Saisine en dessous du seuil de soumission au contrôle',
      'Autre'
    ].sort
  end

  def badge_perimetre_organisme(acte)
    return '' unless acte.perimetre == 'organisme'

    content_tag(:span, acte.perimetre.capitalize, class: 'fr-badge fr-badge--purple-glycine')
  end

  def badge_categorie_organisme(acte)
    return '' unless acte.perimetre == 'organisme' && acte.categorie_organisme.present?

    badge_color = acte.categorie_organisme == 'recette' ? 'fr-badge--green-tilleul-verveine' : 'fr-badge--blue-ecume'
    content_tag(:span, acte.categorie_organisme.capitalize, class: "fr-badge #{badge_color}")
  end

  def etape2_complete?(acte)
    if acte.perimetre == 'organisme'
      if acte.categorie_organisme == 'depense'
        !acte.disponibilite_credits.nil?
      elsif acte.categorie_organisme == 'recette' && acte.operation_compte_tiers == true
        !acte.conformite.nil?
      else
        !acte.imputation_depense.nil?
      end
    else
      !acte.disponibilite_credits.nil?
    end
  end
end
