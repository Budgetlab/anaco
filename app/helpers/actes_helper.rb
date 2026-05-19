module ActesHelper
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
    when 'clôturé en pré-instruction'
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
    elsif etat == "clôturé en pré-instruction"
      "Acte clôturé en pré-instruction avec succès."
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
      "Acte non soumis au contrôle",
      'Compatibilité avec la programmation',
      "Construction de l'EJ",
      "Alerte contrôle interne",
      'Disponibilité des crédits',
      'Évaluation de la consommation des crédits',
      'Fondement juridique',
      "Hors périmètre du CBR/DCB",
      "Impact à prendre en compte dans le prochain budget",
      'Imputation',
      "Non-conformité du bon de commande avec les prix du BPU ou du marché",
      'Pièce(s) manquante(s)',
      "Problème dans la rédaction de l'acte",
      'Risque au titre de la RGP',
      'Saisine a posteriori',
      'Saisine en dessous du seuil de soumission au contrôle',
      'Autre'
    ].sort
  end

  def tous_types_motifs_suspensions
    [
      "Demande de précisions",
      "Demande d'éléments complémentaires",
      "Défaut du circuit d'approbation Chorus",
      "Demande de mise en cohérence EJ /PJ",
      "Erreur d'imputation",
      "Erreur dans la construction de l'EJ",
      "Mauvaise évaluation de la consommation des crédits",
      "Non conformité des pièces",
      "Pièce(s) manquante(s)",
      "Problématique de compatibilité avec la programmation",
      "Problématique de disponibilité des crédits",
      "Problématique de soutenabilité",
      "Saisine a posteriori",
      "Autre",
    ].sort
  end

  def badge_perimetre(acte)
    if acte.perimetre == 'organisme'
      content_tag(:span, acte.perimetre.capitalize, class: 'fr-badge fr-badge--purple-glycine')
    elsif acte.perimetre == 'etat'
      content_tag(:span, acte.perimetre.capitalize, class: 'fr-badge fr-badge--green-menthe')
    else
      ''
    end
  end

  def format_categorie_organisme(categorie)
    case categorie
    when 'depense'
      'Dépense'
    when 'recette'
      'Recette'
    else
      categorie&.capitalize
    end
  end

  def badge_categorie_organisme(acte)
    return '' unless acte.perimetre == 'organisme' && acte.categorie_organisme.present?

    badge_color = acte.categorie_organisme == 'recette' ? 'fr-badge--green-tilleul-verveine' : 'fr-badge--blue-ecume'
    content_tag(:span, format_categorie_organisme(acte.categorie_organisme), class: "fr-badge #{badge_color}")
  end

  def badge_categorie_t2(acte)
    return '' unless acte.titre == 'T2' && acte.categorie_t2.present?

    badge_color = acte.categorie_t2 == 'hors contrat' ? 'fr-badge--beige-gris-galet' : ''
    content_tag(:span, acte.categorie_t2.capitalize, class: "fr-badge #{badge_color}".strip)
  end

  def badge_titre(acte)
    return '' unless acte.titre.present?

    color_class = acte.titre == 'T2' ? 'fr-tag--t2' : 'fr-tag--ht2'
    content_tag(:span, acte.titre, class: "fr-tag fr-tag--static #{color_class}")
  end

  def etape2_complete?(acte)
    return true if acte.titre == 'T2'

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

  # Story 3.2 — true si EXCLUSIVEMENT le périmètre cible est sélectionné dans q_params[:perimetre_in].
  # Reproduit la sémantique de l'ancien `perimetre_eq == target` (scalaire) pour les vues
  # qui doivent rester en "vue État seule" ou "vue Organisme seule" (vs. vue consolidée).
  def perimetre_exclusively?(q_params, target)
    selected = Array((q_params || {})[:perimetre_in]).reject(&:blank?)
    selected == [target]
  end

  # Story 3.3 — Colonnes du sheet T2 dans les exports xlsx (index.xlsx.axlsx, historique.xlsx.axlsx).
  # Format : [libellé, périmètre (:common | :etat | :organisme)]
  # Le périmètre est dérivé des specs Story 2.x : un champ est :etat si présent uniquement sur perimetre='etat'
  # (ex. ISP, accords RFFIM/DB, avis CBCM), :organisme si présent uniquement sur perimetre='organisme'
  # (enveloppe abondée, nom organisme), :common sinon.
  def t2_export_columns
    [
      # ─── Section A : Communes (réutilisées du sheet HT2) ──────────────────
      ['Périmètre',                       :common],
      ['Type Acte',                       :common],
      ['Exercice',                        :common],
      ['Numéro Acte',                     :common],
      ['Etat',                            :common],
      ['Pré-instruction',                 :common],
      ['Catégorie T2',                    :common],
      ['Nom organisme',                   :organisme],
      ['Programme',                       :etat],
      ['Centre financier',                :etat],
      ['Instructeur',                     :common],
      ['Nature',                          :common],
      ['Ordonnateur',                     :common],
      ['Objet',                           :common],
      ['Bénéficiaire',                    :common],
      ['Montant au contrôle',             :common],
      ['Opération budgétaire',            :organisme],
      ['Budget exécutoire',               :organisme],
      ['Délibération CA',                 :organisme],
      ['N° délibération',                 :organisme],
      ['Date délibération',               :organisme],
      ['Observations délibération',       :organisme],
      ['Date création',                   :common],
      ['Date de saisine',                 :common],
      # ─── Section C : Suspension (dernière suspension uniquement) ──────────
      ['Suspension',                      :common],
      ['Date de suspension',              :common],
      ['Date fin de suspension',          :common],
      ['Motif suspension',                :common],
      ['Date limite de réponse',          :common],
      # ─── Section B : Décision ──────────────────────────────────────────────
      ['Proposition décision',            :common],
      ['Décision finale',                 :common],
      ['Valideur',                        :common],
      ['Date clôture',                    :common],
      ['Délai de traitement',             :common],
      ['Type observations',               :common],
      ['Observations',                    :common],
      ['Commentaire interne',             :common],
      ['Services votés',                  :common],
      ['Engagement éligible à la gestion des SV', :common],
      ['Acte programmé',                  :common],
      ['Programmation initiale transmise', :common],
      ['Compatibilité programmation',     :common],
      ['Autorisation tutelle',            :common],
      ['Soutenabilité / Disponibilité des crédits', :common],
      # ─── Section D : Critères de contrôle T2 (t2_details) ─────────────────
      ['Inscription PAP',                 :common],
      ['Respect plafond emplois',         :common],
      ['Respect schéma emplois',          :common],
      ['Contrôle modalités',              :common],
      ['Respect enveloppe',               :common],
      ['Risque réconventionnel',          :common],
      # ─── Section E : Critères de contrôle réutilisés depuis actes ─────────
      ["Exactitude de l'évaluation budgétaire", :common],
      # ─── Section F : Champs nature-spécifiques (t2_details, schema order) ─
      ['Effectifs',                       :common],
      ['Effectifs complémentaires',       :common],
      ['Corps',                           :common],
      ['Catégorie',                       :common],
      ['Date arrêté concours',            :common],
      ["Date d'effet de l'acte",          :common],
      ['Impact schéma emplois',           :common],
      ['Impact autre CBCM/CBR',           :common],
      ['ISP Cercle 1 présent',            :etat],
      ['ISP C1 natures',                  :etat],
      ['ISP C1 montant',                  :etat],
      ['ISP C1 enveloppe SGG',            :etat],
      ['ISP C1 consommation',             :etat],
      ['ISP Cercle 2 présent',            :etat],
      ['ISP C2 natures',                  :etat],
      ['ISP C2 montant',                  :etat],
      ['ISP C2 enveloppe SGG',            :etat],
      ['ISP C2 consommation',             :etat],
      ['FA technique',                    :common],
      ['Enveloppe abondée',               :organisme],
      ['Accord RFFIM',                    :etat],
      ['Sollicitation DB',                :etat],
      ['Avis CBCM',                       :etat],
      ['Périmètre de la mesure',          :common],
      ['Statut agents',                   :common],
      ['Impact financier N+1',            :common],
      ['Origine financement',             :common],
      ['Montant enveloppe N-1',           :common],
      ['Impact maximal sans enveloppe',   :common],
      ['Déclinaison référentiel',         :common],
    ]
  end

  # Story 3.3 — Construit la ligne de valeurs T2 pour un acte donné.
  # Retourne un Array aligné sur t2_export_columns. Les cellules non applicables au périmètre
  # de l'acte renvoient "N/A" (cohérent avec le sheet HT2). t2_detail nil → cellules vides.
  def t2_export_row(acte)
    bool = ->(val) { val.nil? ? "" : (val ? "Oui" : "Non") }
    td = acte.t2_detail
    is_etat = acte.perimetre == 'etat'
    is_organisme = acte.perimetre == 'organisme'
    nature = acte.nature

    last_susp = acte.suspensions.max_by { |s| s.date_suspension || s.created_at }
    last_susp_motif = Array(last_susp&.motif).join(", ")

    # Prédicats de la matrice Story 2.9 — alignés sur _acte_details_t2.html.erb pour éviter toute divergence
    show_acte_programme       = nature != 'ISP' && !(nature == 'Fongibilité asymétrique' && is_organisme)
    show_prog_init_transmise  = nature != 'ISP' && is_etat
    show_programmation_compat = acte.services_votes == false &&
                                show_acte_programme &&
                                (is_etat ? acte.avis_programmation == true : acte.budget_executoire == true)
    show_autorisation_tutelle = !['ISP', 'Fongibilité asymétrique'].include?(nature) &&
                                is_organisme &&
                                acte.budget_executoire == false

    [
      # ─── Section A ──────────────────────────────────────────────────────
      acte.perimetre&.capitalize,
      acte.type_acte,
      acte.annee,
      acte.numero_formate,
      etat_acte(acte),
      bool.(acte.pre_instruction),
      acte.categorie_t2&.capitalize,
      is_etat ? "N/A" : acte.nom_organisme,
      is_organisme ? "N/A" : acte.programme_principal&.numero,
      is_organisme ? "N/A" : acte.centre_financier_code,
      acte.instructeur,
      acte.nature,
      acte.ordonnateur,
      acte.objet,
      acte.beneficiaire,
      acte.montant_ae,
      is_etat ? "N/A" : acte.operation_budgetaire,
      is_etat ? "N/A" : bool.(acte.budget_executoire),
      is_etat ? "N/A" : bool.(acte.deliberation_ca),
      is_etat ? "N/A" : acte.numero_deliberation_ca,
      is_etat ? "N/A" : acte.date_deliberation_ca&.strftime('%d/%m/%Y'),
      is_etat ? "N/A" : acte.observations_deliberation_ca,
      acte.created_at&.strftime('%d/%m/%Y'),
      acte.date_saisine&.strftime('%d/%m/%Y'),
      # ─── Section C : Suspension ────────────────────────────────────────
      last_susp.present? ? "Oui" : "Non",
      last_susp&.date_suspension&.strftime('%d/%m/%Y'),
      last_susp&.date_reprise&.strftime('%d/%m/%Y'),
      last_susp_motif,
      acte.date_limite&.strftime('%d/%m/%Y'),
      # ─── Section B : Décision ──────────────────────────────────────────
      acte.proposition_decision,
      acte.decision_finale,
      acte.valideur,
      acte.date_cloture&.strftime('%d/%m/%Y'),
      acte.delai_traitement,
      (acte.type_observations&.join(", ") if acte.type_observations.present?),
      acte.observations,
      acte.commentaire_proposition_decision,
      bool.(acte.services_votes),
      acte.services_votes ? bool.(acte.programmation) : "N/A",
      # Acte programmé / Programmation initiale transmise / Compatibilité programmation
      # / Autorisation tutelle / Soutenabilité-Disponibilité (regroupés visuellement comme HT2)
      (show_acte_programme       ? bool.(acte.programmation_prevue)   : "N/A"),
      (show_prog_init_transmise  ? bool.(acte.avis_programmation)     : "N/A"),
      (show_programmation_compat ? bool.(acte.programmation)          : "N/A"),
      (show_autorisation_tutelle ? bool.(acte.autorisation_tutelle)   : "N/A"),
      (nature != 'Annexe financière' ? bool.(acte.soutenabilite)      : "N/A"),
      # ─── Section D + E : critères de contrôle T2 (matrice Story 2.9) ───
      # Chaque critère renvoie "N/A" quand il n'a pas lieu d'être pour la
      # combinaison nature × périmètre × état de l'acte.
      ((is_etat && ['Annexe financière', 'Mesure transversale', 'Référentiel'].include?(nature)) ? bool.(td&.inscription_pap) : "N/A"),
      (nature == 'Annexe financière' ? bool.(td&.respect_plafond_emplois) : "N/A"),
      ((nature == 'Annexe financière' && td&.impact_schema_emplois == true) ? bool.(td&.respect_schema_emplois) : "N/A"),
      ((nature == 'Fongibilité asymétrique' && is_etat) ? bool.(td&.controle_modalites) : "N/A"),
      (nature == 'ISP' ? bool.(td&.respect_enveloppe) : "N/A"),
      (['Mesure transversale', 'Référentiel'].include?(nature) ? bool.(td&.risque_reconventionnel) : "N/A"),
      # Section E — critères réutilisés depuis `actes`
      (['Fongibilité asymétrique', 'Marché', 'Mesure transversale'].include?(nature) ? bool.(acte.consommation_credits) : "N/A"),
      # ─── Section F : champs nature-spécifiques (t2_details) ────────────
      td&.effectifs,
      td&.effectifs_complementaire,
      td&.corps,
      Array(td&.grade).join(', '),
      td&.date_arrete_concours&.strftime('%d/%m/%Y'),
      td&.date_effet_acte,
      bool.(td&.impact_schema_emplois),
      bool.(td&.impact_autre_cbcm),
      is_organisme ? "N/A" : bool.(td&.isp_cercle1),
      is_organisme ? "N/A" : Array(td&.isp_cercle1_natures).join(', '),
      is_organisme ? "N/A" : td&.isp_cercle1_montant,
      is_organisme ? "N/A" : td&.isp_cercle1_enveloppe_sgg,
      is_organisme ? "N/A" : td&.isp_cercle1_consommation,
      is_organisme ? "N/A" : bool.(td&.isp_cercle2),
      is_organisme ? "N/A" : Array(td&.isp_cercle2_natures).join(', '),
      is_organisme ? "N/A" : td&.isp_cercle2_montant,
      is_organisme ? "N/A" : td&.isp_cercle2_enveloppe_sgg,
      is_organisme ? "N/A" : td&.isp_cercle2_consommation,
      bool.(td&.fa_technique),
      is_etat ? "N/A" : td&.enveloppe_abondee,
      is_organisme ? "N/A" : bool.(td&.accord_rffim),
      is_organisme ? "N/A" : td&.sollicitation_db,
      is_organisme ? "N/A" : td&.avis_cbcm,
      Array(td&.perimetre_mesure).join(', '),
      td&.statut_agents,
      td&.impact_financier_n1,
      Array(td&.origine_financement).join(', '),
      td&.montant_enveloppe_n1,
      td&.impact_maximal_sans_enveloppe,
      (nature == 'Référentiel' ? bool.(td&.referentiel_type) : "N/A"),
    ]
  end

  # Story 3.3 — Indices des colonnes monétaires (float) et entières dans t2_export_columns
  # pour appliquer les styles number/integer dans les vues sans dupliquer les indexes.
  # Retourne un Hash { float: [...], integer: [...], text: [...] }
  def t2_export_column_indices
    cols = t2_export_columns
    label_idx = ->(label) { cols.index { |(l, _)| l == label } }
    {
      float: [
        label_idx.('Montant au contrôle'),
        label_idx.('ISP C1 montant'),
        label_idx.('ISP C1 enveloppe SGG'),
        label_idx.('ISP C1 consommation'),
        label_idx.('ISP C2 montant'),
        label_idx.('ISP C2 enveloppe SGG'),
        label_idx.('ISP C2 consommation'),
        label_idx.('Impact financier N+1'),
        label_idx.('Montant enveloppe N-1'),
        label_idx.('Impact maximal sans enveloppe'),
        label_idx.('Effectifs'),
        label_idx.('Effectifs complémentaires'),
      ].compact,
      integer: [
        label_idx.('Exercice'),
        label_idx.('Délai de traitement'),
      ].compact,
    }
  end
end
