module AvisHelper

  # Liste des statuts possibles pour une phase d'avis (ex: 'début de gestion').
  # Source : Avi::STATUTS_PAR_PHASE.
  def statuts_for_phase(phase)
    Avi::STATUTS_PAR_PHASE.fetch(phase, [])
  end

  # Mémoïze les phases d'une année pour éviter N+1 quand le tableau de remplissage
  # rend N lignes (chaque ligne interroge plusieurs fois le calendrier de l'année).
  def phases_for_annee(annee)
    @_phases_for_annee_cache ||= {}
    @_phases_for_annee_cache[annee] ||= Phase.pour_annee(annee).to_a
  end

  # Phases d'une année groupées par nom, chaque liste ordonnée par date_debut.
  # Hash : { 'services votés' => [Phase, ...], 'début de gestion' => [Phase], ... }
  # Permet au partial d'empiler N badges par cellule (SV1, SV2, ...).
  def phases_groupees_par_nom(annee)
    @_phases_groupees_cache ||= {}
    @_phases_groupees_cache[annee] ||= phases_for_annee(annee).sort_by(&:date_debut).group_by(&:nom)
  end

  # Noms de phases réellement présents dans le calendrier de l'année (ex: 2024
  # n'a pas "services votés"). Préserve l'ordre canonique défini par Phase::NOMS_CONNUS.
  # Sert à générer dynamiquement les colonnes du tableau remplissage_avis.
  def noms_phases_pour_annee(annee)
    noms_existants = phases_for_annee(annee).map(&:nom).uniq
    Phase::NOMS_CONNUS.select { |nom| noms_existants.include?(nom) }
  end

  # Trouve l'avis lié à une instance précise de Phase via phase_id.
  # Les avis legacy sans phase_id ne sont pas matchés ici (cas marginal après backfill).
  def avis_pour_phase(avis_bop, phase)
    avis_bop.find { |a| a.phase_id == phase.id }
  end

  # Indique si la phase (par son nom) est ouverte à la saisie pour l'année affichée
  # à la date de référence. Une phase est ouverte ssi au moins une instance de ce nom
  # dans l'année a une date_debut <= référence. Une phase absente du calendrier de
  # l'année (ex: services votés en 2024) est par construction non ouverte.
  def phase_ouverte?(phase_nom, annee, reference_date = Date.today)
    phases_for_annee(annee).any? { |p| p.nom == phase_nom && p.date_debut <= reference_date }
  end

  # Badge HTML pour une case (phase, bop) du tableau de remplissage.
  # avis        : avis associé à cette instance de phase (ou nil).
  # avis_debut  : avis 'début de gestion' (utilisé pour CRG1 → N/A si !is_crg1).
  # prefix      : libellé court préfixant le label (ex: "SV1") quand il y a plusieurs
  #               instances de la même phase dans l'année.
  def phase_status_badge(avis, phase, ouverte, avis_debut: nil, prefix: nil)
    label_with_prefix = ->(label) { prefix ? "#{prefix} #{label}" : label }

    return content_tag(:p, label_with_prefix.call('N/A'), class: 'fr-badge') if phase == 'CRG1' && avis_debut&.is_crg1 == false

    unless ouverte
      return content_tag(:p, class: 'fr-badge') do
        concat content_tag(:span, '', class: 'fr-icon-git-repository-private-fill fr-icon--sm', 'aria-hidden': true)
        concat label_with_prefix.call('Non ouvert')
      end
    end

    if avis.nil?
      return content_tag(:p, class: 'fr-badge fr-badge--warning fr-badge--no-icon') do
        concat content_tag(:span, '', class: 'fr-icon-edit-fill fr-icon--sm', 'aria-hidden': true)
        concat label_with_prefix.call('À rédiger')
      end
    end

    case
    when avis.etat == 'Brouillon'
      content_tag(:p, label_with_prefix.call('Brouillon'), class: 'fr-badge fr-badge--new fr-badge--no-icon')
    when avis.statut == 'Non reçu'
      content_tag(:p, label_with_prefix.call('Non reçu'), class: 'fr-badge fr-badge--brown-caramel')
    else
      content_tag(:p, class: 'fr-badge fr-badge--info fr-badge--no-icon') do
        concat content_tag(:span, '', class: 'fr-icon-checkbox-circle-fill fr-icon--sm', 'aria-hidden': true)
        concat label_with_prefix.call('Transmis')
      end
    end
  end

  # Prochaine instance de Phase à rédiger pour un BOP, ou nil si tout est transmis.
  # Itère sur les phases de l'année dans l'ordre chronologique. Une instance est
  # candidate si elle est ouverte ET (pas d'avis associé OU avis en brouillon).
  # CRG1 est sauté si l'avis début existe avec is_crg1 == false (cas N/A).
  # Retourne l'objet Phase (pas le nom) pour cibler une instance précise — utile
  # quand plusieurs phases du même nom coexistent (SV1, SV2).
  def next_phase_to_fill(avis_bop, annee, reference_date = Date.today)
    avis_debut = avis_bop.find { |a| a.phase == 'début de gestion' }

    phases_for_annee(annee).sort_by(&:date_debut).each do |phase|
      next unless phase.ouverte?(reference_date)
      next if phase.nom == 'CRG1' && avis_debut&.is_crg1 == false

      avis = avis_pour_phase(avis_bop, phase)
      return phase if avis.nil? || avis.etat == 'Brouillon'
    end
    nil
  end

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
    when 'Non reçu'
      'fr-badge fr-badge--brown-caramel'
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
    avis_phase = avis.select { |a| a.phase == phase }
    avis_non_recu = avis_phase.count { |a| a.statut == 'Non reçu' }
    avis_date_1 = avis_phase.count { |a| !a.date_reception.nil? && a.date_reception <= Date.new(annee, 3, 1) }
    avis_date_2 = avis_phase.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 1) && a.date_reception <= Date.new(annee, 3, 15) }
    avis_date_3 = avis_phase.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 3, 15) && a.date_reception <= Date.new(annee, 3, 31) }
    avis_date_4 = avis_phase.count { |a| !a.date_reception.nil? && a.date_reception > Date.new(annee, 4, 1) }
    avis_vide = [avis_total - avis_date_1 - avis_date_2 - avis_date_3 - avis_date_4 - avis_non_recu, 0].max
    [avis_date_1, avis_date_2, avis_date_3, avis_date_4, avis_non_recu, avis_vide]
  end

  # Pour chaque phase de l'année sélectionnée, renvoie la répartition des statuts
  # (statuts métier de la phase + "Non reçu" si présent + "Non renseigné" pour le reliquat).
  # avis_total = nombre de BOP actifs sur l'année (référentiel commun).
  def statuts_repartition_par_phase(avis_remplis, avis_total, annee)
    phases = Phase.pour_annee(annee).to_a
    instances_par_nom = phases.group_by(&:nom)

    phases.map do |phase|
      avis_phase = avis_remplis.select { |a| a.phase == phase.nom }
      # Pour 'services votés' multi-instances : ne garder que le dernier avis par BOP
      if phase.nom == 'services votés'
        avis_phase = avis_phase.group_by(&:bop_id).map { |_, list| list.max_by(&:created_at) }
      end

      buckets = (Avi::STATUTS_PAR_PHASE[phase.nom] || []) + ['Non reçu']
      counts = buckets.map { |s| [s, avis_phase.count { |a| a.statut == s }] }.to_h
      renseignes_total = counts.values.sum
      counts['Non renseigné'] = [avis_total - renseignes_total, 0].max

      data = counts.reject { |_, v| v == 0 }.map { |name, y| { name: name, y: y } }
      instances = instances_par_nom[phase.nom] || []
      libelle = instances.size > 1 ? phase.libelle_avec_numero : phase.nom.sub(/\A./, &:upcase)

      { phase_nom: phase.nom, libelle: libelle, data: data }
    end
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
    Avi.where(annee: annee).where.not(etat: 'Brouillon')
  end

  def avis_remplis_phase(avis, phase)
    avis.select { |a| a.phase == phase && a.etat != 'Brouillon' }.count
  end

  def avis_brouillon_phase(avis, phase)
    avis.select { |a| a.phase == phase && a.etat == 'Brouillon' }.count
  end

  def avis_a_remplir(avis, phase, annee)
    case phase
    when 'CRG1'
      # Nombre de CRG1 attendus = nombre d'avis début de gestion finalisés avec is_crg1=true.
      # NB : on filtre sur `etat` (workflow : Brouillon / En attente / Lu), pas `statut`
      # (verdict métier qui ne prend jamais la valeur 'Brouillon').
      avis.select { |a| a.phase == 'début de gestion' && a.is_crg1? && a.etat != 'Brouillon' }.count
    else
      Bop.actifs_en(annee).count
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
    # NB : la clé `users:` correspond au nom de la table (pluriel) produit par
    # `joins(:user)`. L'ancien `'user.statut': ...` cherchait une table `user`
    # (singulier) inexistante → erreur SQL.
    avis.joins(:user).where(users: { statut: 'CBR' }).select { |a| a.phase == phase && a.etat == 'Lu' }.count
  end

  def avis_recus(avis, phase)
    avis.joins(:user).where(users: { statut: 'CBR' }).select { |a| a.phase == phase && a.etat != 'Brouillon' }.count
  end

  def taux_lecture_avis(avis, phase)
    if avis_recus(avis, phase).zero?
      100
    else
      (avis_lus(avis, phase) * 100.0 / avis_recus(avis, phase)).to_f.round
    end
  end

end
