class T2Detail < ApplicationRecord
  belongs_to :acte

  validates :type_acte_t2, inclusion: { in: %w[Initial Complémentaire], allow_nil: true }

  def self.ransackable_attributes(auth_object = nil)
    %w[
      id acte_id type_acte_t2
      effectifs effectifs_complementaire corps grade date_arrete_concours date_effet_acte
      impact_schema_emplois impact_autre_cbcm
      isp_cercle1 isp_cercle1_natures isp_cercle1_montant isp_cercle1_enveloppe_sgg isp_cercle1_consommation
      isp_cercle2 isp_cercle2_natures isp_cercle2_montant isp_cercle2_enveloppe_sgg isp_cercle2_consommation
      fa_technique enveloppe_abondee accord_rffim sollicitation_db avis_cbcm
      perimetre_mesure statut_agents impact_financier_n1 origine_financement
      montant_enveloppe_n1 impact_maximal_sans_enveloppe
      referentiel_type
      inscription_pap respect_plafond_emplois respect_schema_emplois controle_modalites respect_enveloppe risque_reconventionnel
      created_at updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[acte]
  end
end
