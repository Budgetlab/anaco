module BopsHelper

  # fonction pour afficher la répartition des statuts des BOP par phase
  def statut_bop_repartition(avis_remplis, avis_total, annee)
    statuts_debut = statut_bop(avis_remplis, avis_total, 'début de gestion')
    statuts_crg1 = annee != @annee || @date_crg1 <= Date.today ? statut_bop(avis_remplis, avis_total, 'CRG1') : [0, 0, 0, avis_total]
    statuts_crg2 = annee != @annee || @date_crg2 <= Date.today ? statut_bop(avis_remplis, avis_total, 'CRG2') : [0, 0, 0, avis_total]
    [[statuts_debut[0], statuts_crg1[0], statuts_crg2[0]], [statuts_debut[1], statuts_crg1[1], statuts_crg2[1]],
     [statuts_debut[2], statuts_crg1[2], statuts_crg2[2]], [statuts_debut[3], statuts_crg1[3], statuts_crg2[3]]]
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
