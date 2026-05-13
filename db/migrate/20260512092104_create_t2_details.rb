class CreateT2Details < ActiveRecord::Migration[8.1]
  def change
    create_table :t2_details do |t|
      # FK to actes (1:1)
      t.references :acte, null: false, foreign_key: true, index: { unique: true }

      # Section Annexe financière / RH
      t.float   :effectifs
      t.float   :effectifs_complementaire
      t.string  :corps
      t.string  :grade,                  array: true, default: []
      t.date    :date_arrete_concours
      t.string  :date_effet_acte
      t.boolean :impact_schema_emplois
      t.boolean :impact_autre_cbcm

      # Section ISP — Cercle 1
      t.boolean :isp_cercle1
      t.string  :isp_cercle1_natures,    array: true, default: []
      t.decimal :isp_cercle1_montant
      t.decimal :isp_cercle1_enveloppe_sgg
      t.decimal :isp_cercle1_consommation

      # Section ISP — Cercle 2
      t.boolean :isp_cercle2
      t.string  :isp_cercle2_natures,    array: true, default: []
      t.decimal :isp_cercle2_montant
      t.decimal :isp_cercle2_enveloppe_sgg
      t.decimal :isp_cercle2_consommation

      # Section Fongibilité asymétrique
      t.boolean :fa_technique
      t.string  :enveloppe_abondee
      t.boolean :accord_rffim
      t.string  :sollicitation_db
      t.boolean :avis_cbcm

      # Section Mesure transversale + Enveloppe limitative (shared fields)
      t.string  :perimetre_mesure,       array: true, default: []
      t.string  :statut_agents
      t.decimal :impact_financier_n1
      t.string  :origine_financement,    array: true, default: []

      # Section Enveloppe limitative
      t.decimal :montant_enveloppe_n1
      t.decimal :impact_maximal_sans_enveloppe

      # Section Référentiel
      t.string  :referentiel_type

      # Contrôles RH communs T2 (étape 2)
      t.boolean :inscription_pap
      t.boolean :respect_plafond_emplois
      t.boolean :respect_schema_emplois
      t.boolean :controle_modalites
      t.boolean :respect_enveloppe
      t.boolean :risque_reconventionnel

      t.timestamps
    end
  end
end
