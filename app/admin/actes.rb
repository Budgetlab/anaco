ActiveAdmin.register Acte do
  menu priority: 2

  TYPES_OBSERVATIONS = [
    "Acte non soumis au contrôle",
    "Alerte contrôle interne",
    "Autre",
    "Compatibilité avec la programmation",
    "Construction de l'EJ",
    "Disponibilité des crédits",
    "Évaluation de la consommation des crédits",
    "Fondement juridique",
    "Hors périmètre du CBR/DCB",
    "Impact à prendre en compte dans le prochain budget",
    "Imputation",
    "Non-conformité du bon de commande avec les prix du BPU ou du marché",
    "Pièce(s) manquante(s)",
    "Problème dans la rédaction de l'acte",
    "Risque au titre de la RGP",
    "Saisine a posteriori",
    "Saisine en dessous du seuil de soumission au contrôle",
  ].freeze unless defined?(TYPES_OBSERVATIONS)

  # Story 3.4 — Liste unifiée des natures HT2 + T2 (sélecteur filtre)
  # Concat des listes HT2 visa / avis (cf. actes_controller.rb:1329, 1333) + 7 natures T2
  # (cf. actes_controller.rb:1249), dédupliquées et triées alphabétiquement.
  NATURES_FILTER_COLLECTION = (
    [
      # HT2 visa
      "Autre", "Autre contrat", "Bail", "Bon de commande", "Convention",
      "Décision diverse", "Dotation en fonds propres",
      "MAPA mixte", "MAPA à tranches", "MAPA unique",
      "Marché mixte", "Marché unique", "Marché à tranches",
      "Prêt ou avance", "Remboursement de mise à disposition T3",
      "Subvention", "Subvention pour charges d'investissement",
      "Subvention pour charges de service public",
      "Transaction", "Transfert",
      # HT2 avis (4 valeurs uniques — Convention, Transaction, Autre, Autre contrat
      # déjà listées dans la sous-section visa ci-dessus, dédupliquées par .uniq)
      "Accord cadre à bons de commande", "Accord cadre à marchés subséquents",
      "MAPA à bons de commande", "Marché subséquent à bons de commande",
      # T2
      "Annexe financière", "Enveloppe limitative", "Fongibilité asymétrique",
      "ISP", "Marché", "Mesure transversale", "Référentiel",
    ].uniq.sort
  ).freeze unless defined?(NATURES_FILTER_COLLECTION)

  permit_params :type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global,
                :centre_financier_code, :date_saisine, :numero_chorus, :beneficiaire, :objet,
                :ordonnateur, :precisions_acte, :pre_instruction, :action,
                :activite, :numero_tf, :date_limite, :disponibilite_credits, :imputation_depense,
                :consommation_credits, :programmation, :proposition_decision,
                :commentaire_proposition_decision, :observations, :user_id,
                :valideur, :date_cloture, :annee, :decision_finale, :numero_utilisateur,
                :numero_formate, :delai_traitement, :categorie, :numero_marche, :services_votes,
                :liste_actes, :nombre_actes, :type_engagement, :programmation_prevue,
                :groupe_marchandises, :renvoie_instruction, :pdf_generation_status, :perimetre,
                :categorie_organisme, :nom_organisme, :type_montant, :operation_compte_tiers,
                :operation_budgetaire, :nature_categorie_organisme, :budget_executoire,
                :deliberation_ca, :numero_deliberation_ca, :date_deliberation_ca,
                :observations_deliberation_ca, :destination, :nomenclature, :flux, :soutenabilite,
                :conformite, :concordance_recettes_tiers, :autorisation_tutelle,
                :avis_programmation, :gestion_anticipee, :titre, :categorie_t2,
                type_observations: [],
                t2_detail_attributes: [
                  :id, :type_acte_t2,
                  :effectifs, :effectifs_complementaire, :corps, :date_arrete_concours, :date_effet_acte,
                  :impact_schema_emplois, :impact_autre_cbcm,
                  :isp_cercle1, :isp_cercle1_montant, :isp_cercle1_enveloppe_sgg, :isp_cercle1_consommation,
                  :isp_cercle2, :isp_cercle2_montant, :isp_cercle2_enveloppe_sgg, :isp_cercle2_consommation,
                  :fa_technique, :enveloppe_abondee, :accord_rffim, :sollicitation_db, :avis_cbcm,
                  :statut_agents, :impact_financier_n1,
                  :montant_enveloppe_n1, :impact_maximal_sans_enveloppe,
                  :referentiel_type,
                  :inscription_pap, :respect_plafond_emplois, :respect_schema_emplois,
                  :controle_modalites, :respect_enveloppe, :risque_reconventionnel,
                  grade: [], isp_cercle1_natures: [], isp_cercle2_natures: [],
                  perimetre_mesure: [], origine_financement: []
                ]

  before_action only: [:create, :update] do
    params[:acte][:type_observations]&.reject!(&:blank?)

    # Story 3.4 — les 5 colonnes array de t2_details sont exposées comme inputs
    # texte CSV dans le formulaire admin (un input par champ, virgules en séparateur).
    # On convertit ici en Array<String> avant que le strong-params les voie.
    td = params.dig(:acte, :t2_detail_attributes)
    if td.is_a?(ActionController::Parameters) || td.is_a?(Hash)
      %i[grade isp_cercle1_natures isp_cercle2_natures perimetre_mesure origine_financement].each do |k|
        val = td[k]
        td[k] = val.split(',').map(&:strip).reject(&:blank?) if val.is_a?(String)
      end
    end
  end

  index do
    selectable_column
    id_column
    column :numero_formate
    column :type_acte
    column :titre
    column :categorie_t2
    column :etat
    column(:user) { |a| a.user_id }
    column :nature
    column :montant_ae
    column :date_saisine
    column :perimetre
    column :annee
    column :created_at
    actions
  end

  filter :numero_formate
  filter :numero_chorus
  filter :type_acte, as: :select, collection: ['avis', 'visa', 'TF']
  filter :titre, as: :select, collection: ['HT2', 'T2']
  filter :categorie_t2, as: :select, collection: ['contrat', 'hors contrat']
  filter :etat, as: :select, collection: Acte::VALID_ETATS
  filter :perimetre, as: :select, collection: ['etat', 'organisme']
  filter :categorie_organisme, as: :select, collection: ['depense', 'recette']
  filter :user_id, as: :select, collection: -> { User.order(:nom).map { |u| [u.nom, u.id] } }
  filter :nature, as: :select, collection: NATURES_FILTER_COLLECTION
  filter :decision_finale
  filter :annee
  filter :date_saisine
  filter :date_cloture
  filter :montant_ae
  filter :beneficiaire
  filter :ordonnateur
  filter :instructeur
  filter :valideur
  filter :pre_instruction
  filter :created_at
  filter :updated_at

  show do
    attributes_table do
      row :id
      row :numero_formate
      row :numero_utilisateur
      row :titre
      row :categorie_t2
      row :type_acte
      row :etat
      row :perimetre
      row :categorie_organisme
      row(:user) { |a| a.user_id }
      row :annee
      row :numero_chorus
      row :numero_tf
      row :numero_marche
      row :date_saisine
      row :date_limite
      row :date_cloture
      row :delai_traitement
      row :nature
      row :type_engagement
      row :type_montant
      row :montant_ae do |acte|
        number_to_currency(acte.montant_ae, unit: '€', separator: ',', delimiter: ' ')
      end
      row :montant_global do |acte|
        number_to_currency(acte.montant_global, unit: '€', separator: ',', delimiter: ' ') if acte.montant_global
      end
      row :instructeur
      row :ordonnateur
      row :beneficiaire
      row :valideur
      row :centre_financier_code
      row :nom_organisme
      row :action
      row :activite
      row :categorie
      row :groupe_marchandises
      row :destination
      row :nomenclature
      row :flux
      row :operation_compte_tiers
      row :operation_budgetaire
      row :nature_categorie_organisme
      row :disponibilite_credits
      row :imputation_depense
      row :consommation_credits
      row :programmation
      row :programmation_prevue
      row :avis_programmation
      row :soutenabilite
      row :conformite
      row :concordance_recettes_tiers
      row :autorisation_tutelle
      row :budget_executoire
      row :deliberation_ca
      row :numero_deliberation_ca
      row :date_deliberation_ca
      row :observations_deliberation_ca
      row :proposition_decision
      row :commentaire_proposition_decision
      row :decision_finale
      row(:type_observations) { |a| a.type_observations.join(", ") }
      row :observations
      row :precisions_acte
      row :objet
      row :pre_instruction
      row :gestion_anticipee
      row :services_votes
      row :liste_actes
      row :nombre_actes
      row :renvoie_instruction
      row :pdf_generation_status
      row :created_at
      row :updated_at
    end

    if acte.titre == 'T2'
      panel 'Détails T2' do
        if acte.t2_detail.present?
          attributes_table_for acte.t2_detail do
            # Identification
            row :type_acte_t2
            row :referentiel_type

            # Annexe financière / RH commun
            row :effectifs
            row :effectifs_complementaire
            row :corps
            row(:grade) { |td| Array(td.grade).join(', ') }
            row(:date_arrete_concours) { |td| td.date_arrete_concours&.strftime('%d/%m/%Y') }
            row :date_effet_acte
            row :impact_schema_emplois
            row :impact_autre_cbcm

            # ISP Cercle 1
            row :isp_cercle1
            row(:isp_cercle1_natures) { |td| Array(td.isp_cercle1_natures).join(', ') }
            row(:isp_cercle1_montant) { |td| number_to_currency(td.isp_cercle1_montant, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle1_montant }
            row(:isp_cercle1_enveloppe_sgg) { |td| number_to_currency(td.isp_cercle1_enveloppe_sgg, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle1_enveloppe_sgg }
            row(:isp_cercle1_consommation) { |td| number_to_currency(td.isp_cercle1_consommation, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle1_consommation }

            # ISP Cercle 2
            row :isp_cercle2
            row(:isp_cercle2_natures) { |td| Array(td.isp_cercle2_natures).join(', ') }
            row(:isp_cercle2_montant) { |td| number_to_currency(td.isp_cercle2_montant, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle2_montant }
            row(:isp_cercle2_enveloppe_sgg) { |td| number_to_currency(td.isp_cercle2_enveloppe_sgg, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle2_enveloppe_sgg }
            row(:isp_cercle2_consommation) { |td| number_to_currency(td.isp_cercle2_consommation, unit: '€', separator: ',', delimiter: ' ') if td.isp_cercle2_consommation }

            # Fongibilité asymétrique
            row :fa_technique
            row :enveloppe_abondee
            row :accord_rffim
            row :sollicitation_db
            row :avis_cbcm

            # Mesure transversale / Enveloppe limitative
            row(:perimetre_mesure) { |td| Array(td.perimetre_mesure).join(', ') }
            row :statut_agents
            row(:impact_financier_n1) { |td| number_to_currency(td.impact_financier_n1, unit: '€', separator: ',', delimiter: ' ') if td.impact_financier_n1 }
            row(:origine_financement) { |td| Array(td.origine_financement).join(', ') }
            row(:montant_enveloppe_n1) { |td| number_to_currency(td.montant_enveloppe_n1, unit: '€', separator: ',', delimiter: ' ') if td.montant_enveloppe_n1 }
            row(:impact_maximal_sans_enveloppe) { |td| number_to_currency(td.impact_maximal_sans_enveloppe, unit: '€', separator: ',', delimiter: ' ') if td.impact_maximal_sans_enveloppe }

            # Contrôles RH communs T2 (étape 2)
            row :inscription_pap
            row :respect_plafond_emplois
            row :respect_schema_emplois
            row :controle_modalites
            row :respect_enveloppe
            row :risque_reconventionnel

            # Timestamps
            row :id
            row :created_at
            row :updated_at
          end
        else
          para "Aucun T2Detail associé"
        end
      end
    end

    panel 'Suspensions' do
      table_for acte.suspensions do
        column :id
        column :date_suspension
        column :date_reprise
        column(:motif) { |s| s.motif.join(", ") }
        column :observations
        column :created_at
      end
    end

    panel 'Échéanciers' do
      table_for acte.echeanciers do
        column :id
        column :annee
        column :montant_ae
        column :montant_cp
      end
    end

    panel 'Lignes de poste' do
      table_for acte.poste_lignes do
        column :id
        column :numero
        column :centre_financier_code
        column :montant
        column :domaine_fonctionnel
        column :fonds
        column :compte_budgetaire
        column :code_activite
        column :axe_ministeriel
        column :groupe_marchandises
        column :flux
      end
    end

    active_admin_comments
  end

  form do |f|
    f.inputs 'Informations générales' do
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :annee, as: :number
      f.input :type_acte, as: :select, collection: ['avis', 'visa', 'TF']
      f.input :etat, as: :select, collection: Acte::VALID_ETATS
      f.input :perimetre, as: :select, collection: ['etat', 'organisme']
      f.input :categorie_organisme, as: :select, collection: ['depense', 'recette']
      f.input :pre_instruction, as: :boolean
      f.input :gestion_anticipee, as: :boolean
      f.input :avis_programmation, as: :boolean
    end

    f.inputs 'Classification T2' do
      f.input :titre, as: :select, collection: ['HT2', 'T2']
      f.input :categorie_t2, as: :select, collection: ['contrat', 'hors contrat'], include_blank: true
    end

    if f.object.titre == 'T2'
      f.object.build_t2_detail if f.object.t2_detail.nil?

      f.inputs 'Détails T2 (édition admin — toutes natures à plat)', for: [:t2_detail, f.object.t2_detail] do |td|
        td.input :type_acte_t2, as: :select, collection: ['Initial', 'Complémentaire'], include_blank: true

        td.input :effectifs, as: :number, step: 0.01
        td.input :effectifs_complementaire, as: :number, step: 0.01
        td.input :corps
        td.input :grade, as: :string,
                 input_html: { value: Array(td.object.grade).join(', ') },
                 hint: 'Liste séparée par des virgules'
        td.input :date_arrete_concours, as: :datepicker
        td.input :date_effet_acte
        td.input :impact_schema_emplois, as: :boolean
        td.input :impact_autre_cbcm, as: :boolean

        td.input :isp_cercle1, as: :boolean
        td.input :isp_cercle1_natures, as: :string,
                 input_html: { value: Array(td.object.isp_cercle1_natures).join(', ') },
                 hint: 'Liste séparée par des virgules'
        td.input :isp_cercle1_montant, as: :number, step: 0.01
        td.input :isp_cercle1_enveloppe_sgg, as: :number, step: 0.01
        td.input :isp_cercle1_consommation, as: :number, step: 0.01

        td.input :isp_cercle2, as: :boolean
        td.input :isp_cercle2_natures, as: :string,
                 input_html: { value: Array(td.object.isp_cercle2_natures).join(', ') },
                 hint: 'Liste séparée par des virgules'
        td.input :isp_cercle2_montant, as: :number, step: 0.01
        td.input :isp_cercle2_enveloppe_sgg, as: :number, step: 0.01
        td.input :isp_cercle2_consommation, as: :number, step: 0.01

        td.input :fa_technique, as: :boolean
        td.input :enveloppe_abondee, as: :text
        td.input :accord_rffim, as: :boolean
        td.input :sollicitation_db, as: :text
        td.input :avis_cbcm, as: :text

        td.input :perimetre_mesure, as: :string,
                 input_html: { value: Array(td.object.perimetre_mesure).join(', ') },
                 hint: 'Liste séparée par des virgules'
        td.input :statut_agents, as: :text
        td.input :impact_financier_n1, as: :number, step: 0.01
        td.input :origine_financement, as: :string,
                 input_html: { value: Array(td.object.origine_financement).join(', ') },
                 hint: 'Liste séparée par des virgules'
        td.input :montant_enveloppe_n1, as: :number, step: 0.01
        td.input :impact_maximal_sans_enveloppe, as: :number, step: 0.01

        td.input :referentiel_type, as: :boolean

        td.input :inscription_pap, as: :boolean
        td.input :respect_plafond_emplois, as: :boolean
        td.input :respect_schema_emplois, as: :boolean
        td.input :controle_modalites, as: :boolean
        td.input :respect_enveloppe, as: :boolean
        td.input :risque_reconventionnel, as: :boolean
      end
    end

    f.inputs 'Numérotation' do
      f.input :numero_utilisateur, as: :number
      f.input :numero_formate
      f.input :numero_chorus
      f.input :numero_tf
      f.input :numero_marche
    end

    f.inputs 'Dates' do
      f.input :date_saisine, as: :datepicker
      f.input :date_limite, as: :datepicker
      f.input :date_cloture, as: :datepicker
      f.input :date_deliberation_ca, as: :datepicker
    end

    f.inputs 'Nature et montants' do
      f.input :nature
      f.input :type_engagement
      f.input :type_montant, as: :select, collection: ['TTC', 'HT']
      f.input :montant_ae, as: :number, step: 0.01
      f.input :montant_global, as: :number, step: 0.01
    end

    f.inputs 'Acteurs' do
      f.input :instructeur
      f.input :ordonnateur
      f.input :beneficiaire
      f.input :valideur
    end

    f.inputs 'Localisation' do
      f.input :centre_financier_code
      f.input :nom_organisme
    end

    f.inputs 'Imputation budgétaire' do
      f.input :action
      f.input :activite
      f.input :categorie
      f.input :groupe_marchandises
      f.input :destination
      f.input :nomenclature
      f.input :flux
    end

    f.inputs 'Opérations' do
      f.input :operation_compte_tiers, as: :boolean
      f.input :operation_budgetaire
      f.input :nature_categorie_organisme
    end

    f.inputs 'Contrôles' do
      f.input :disponibilite_credits, as: :boolean
      f.input :imputation_depense, as: :boolean
      f.input :consommation_credits, as: :boolean
      f.input :programmation, as: :boolean
      f.input :programmation_prevue, as: :boolean
      f.input :soutenabilite, as: :boolean
      f.input :conformite, as: :boolean
      f.input :concordance_recettes_tiers, as: :boolean
      f.input :autorisation_tutelle, as: :boolean
    end

    f.inputs 'Délibérations et budgets' do
      f.input :budget_executoire, as: :boolean
      f.input :deliberation_ca, as: :boolean
      f.input :numero_deliberation_ca
      f.input :observations_deliberation_ca, as: :text
    end

    f.inputs 'Décisions' do
      f.input :proposition_decision
      f.input :commentaire_proposition_decision, as: :text
      f.input :decision_finale
      f.input :delai_traitement, as: :number
    end

    f.inputs 'Observations et précisions' do
      f.input :type_observations, as: :check_boxes, collection: TYPES_OBSERVATIONS, multiple: true
      f.input :observations, as: :text
      f.input :precisions_acte, as: :text
      f.input :objet, as: :text
    end

    f.inputs 'Divers' do
      f.input :services_votes, as: :boolean
      f.input :liste_actes, as: :boolean
      f.input :nombre_actes, as: :number
      f.input :renvoie_instruction, as: :boolean
      f.input :pdf_generation_status
    end

    f.actions
  end

end
