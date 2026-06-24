module BopsHelper

  # Répartition des statuts des BOP par phase de l'année (toutes phases existantes).
  # Buckets : capacité contributive (delta budget > 0), consommation à la ressource (= 0),
  # besoin de financement (< 0), Non reçu (statut = 'Non reçu'), Non renseigné (reliquat).
  # Les avis Non reçu sont exclus du calcul du delta budget.
  def statut_bop_repartition(avis_remplis, avis_total, annee)
    phases = Phase.pour_annee(annee).to_a
    instances_par_nom = phases.group_by(&:nom)

    categories = []
    capacite, consommation, besoin, non_recu, non_renseigne = [], [], [], [], []

    phases.each do |phase|
      avis_phase = avis_remplis.select { |a| a.phase == phase.nom }
      if phase.nom == 'services votés'
        avis_phase = avis_phase.group_by(&:bop_id).map { |_, list| list.max_by(&:created_at) }
      end

      nr = avis_phase.count { |a| a.statut == 'Non reçu' }
      avis_budget = avis_phase.reject { |a| a.statut == 'Non reçu' }
      pos = avis_budget.count { |a| delta_budget(a).positive? }
      nul = avis_budget.count { |a| delta_budget(a).zero? }
      neg = avis_budget.count { |a| delta_budget(a).negative? }
      vide = [avis_total - pos - nul - neg - nr, 0].max

      instances = instances_par_nom[phase.nom] || []
      categories << (instances.size > 1 ? phase.libelle_court_avec_numero : phase.nom.sub(/\A./, &:upcase))
      capacite << pos
      consommation << nul
      besoin << neg
      non_recu << nr
      non_renseigne << vide
    end

    { categories: categories, series: [capacite, consommation, besoin, non_recu, non_renseigne] }
  end

  def delta_budget(a)
    ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0))
  end

  # fonction pour calculer les statuts des bops sur une phase
  def statut_bop(avis, avis_total, phase)
    if phase == 'CRG1'
      statuts_positive = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).positive? } + avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).positive? }
      statuts_nul = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).zero? } + avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).zero? }
      statuts_negative = avis.count { |a| a.phase == 'début de gestion' && a.is_crg1 == false && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).negative? } + avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).negative? }
      statuts_vide = avis_total - avis.select { |a| a.phase == 'début de gestion' && a.is_crg1 == false }.count - avis.count { |a| a.phase == phase }
    else
      statuts_positive = avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).positive? }
      statuts_nul = avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).zero? }
      statuts_negative = avis.count { |a| a.phase == phase && ((a.ae_i || 0) + (a.t2_i || 0) - (a.ae_f || 0) - (a.t2_f || 0)).negative? }
      statuts_vide = avis_total - avis.count { |a| a.phase == phase }
    end
    [statuts_positive, statuts_nul, statuts_negative, statuts_vide]
  end
end
