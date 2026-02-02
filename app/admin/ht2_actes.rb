ActiveAdmin.register Ht2Acte do
  menu priority: 2

  # Paramètres autorisés
  permit_params :type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global,
                :centre_financier_code, :date_chorus, :numero_chorus, :beneficiaire, :objet,
                :ordonnateur, :precisions_acte, :pre_instruction, :action, :sous_action,
                :activite, :numero_tf, :date_limite, :disponibilite_credits, :imputation_depense,
                :consommation_credits, :programmation, :proposition_decision,
                :commentaire_proposition_decision, :observations, :user_id,
                :commentaire_disponibilite_credits, :valideur, :date_cloture, :annee,
                :decision_finale, :numero_utilisateur, :numero_formate, :delai_traitement,
                :sheet_data, :categorie, :numero_marche, :services_votes, :liste_actes,
                :nombre_actes, :type_engagement, :programmation_prevue, :groupe_marchandises,
                :renvoie_instruction, :pdf_generation_status, :perimetre, :categorie_organisme,
                :nom_organisme, :type_montant, :operation_compte_tiers, :operation_budgetaire,
                :nature_categorie_organisme, :budget_executoire, :deliberation_ca,
                :numero_deliberation_ca, :date_deliberation_ca, :observations_deliberation_ca,
                :destination, :nomenclature, :flux, :soutenabilite, :conformite,
                :concordance_recettes_tiers, :autorisation_tutelle, type_observations: []

  # Index (liste)
  index do
    selectable_column
    id_column
    column :numero_formate
    column :type_acte
    column :etat
    column :user
    column :nature
    column :montant_ae do |acte|
      number_to_currency(acte.montant_ae, unit: '€', separator: ',', delimiter: ' ')
    end
    column :date_chorus
    column :perimetre
    column :annee
    column :created_at
    actions
  end

  # Filtres
  filter :numero_formate
  filter :numero_chorus
  filter :type_acte, as: :select, collection: ['avis', 'visa', 'TF']
  filter :etat, as: :select, collection: Ht2Acte::VALID_ETATS
  filter :perimetre, as: :select, collection: ['etat', 'organisme']
  filter :categorie_organisme, as: :select, collection: ['depense', 'recette']
  filter :user
  filter :nature
  filter :decision_finale
  filter :annee
  filter :date_chorus
  filter :date_cloture
  filter :montant_ae
  filter :beneficiaire
  filter :ordonnateur
  filter :instructeur
  filter :valideur
  filter :pre_instruction
  filter :created_at
  filter :updated_at

  # Formulaire
  form do |f|
    f.inputs 'Informations générales' do
      f.input :user, as: :select, collection: User.order(:nom)
      f.input :annee, as: :number
      f.input :type_acte, as: :select, collection: ['avis', 'visa', 'TF']
      f.input :etat, as: :select, collection: Ht2Acte::VALID_ETATS
      f.input :perimetre, as: :select, collection: ['etat', 'organisme']
      f.input :categorie_organisme, as: :select, collection: ['depense', 'recette']
      f.input :pre_instruction, as: :boolean
    end

    f.inputs 'Numérotation' do
      f.input :numero_utilisateur, as: :number
      f.input :numero_formate
      f.input :numero_chorus
      f.input :numero_tf
      f.input :numero_marche
    end

    f.inputs 'Dates' do
      f.input :date_chorus, as: :datepicker
      f.input :date_limite, as: :datepicker
      f.input :date_cloture, as: :datepicker
      f.input :date_deliberation_ca, as: :datepicker
    end

    f.inputs 'Nature et montants' do
      f.input :nature
      f.input :type_engagement
      f.input :type_montant
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
      f.input :sous_action
      f.input :activite
      f.input :categorie
      f.input :groupe_marchandises
      f.input :destination
      f.input :nomenclature
      f.input :flux
    end

    f.inputs 'Opérations' do
      f.input :operation_compte_tiers
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
      f.input :budget_executoire
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
      f.input :type_observations, as: :select, collection: [
        "Acte déjà signé par l'ordonnateur",
        "Acte non soumis au contrôle",
        "Compatibilité avec la programmation",
        "Construction de l'EJ",
        "Disponibilité des crédits",
        "Évaluation de la consommation des crédits",
        "Fondement juridique",
        "Hors périmètre du CBR/DCB",
        "Impact à prendre en compte dans le prochain budget",
        "Imputation",
        "Pièce(s) manquante(s)",
        "Problème dans la rédaction de l'acte",
        "Risque au titre de la RGP",
        "Saisine a posteriori",
        "Saisine à postériori",
        "Saisine en dessous du seuil de soumission au contrôle",
        "Autre"
      ], input_html: { multiple: true }
      f.input :observations, as: :text
      f.input :precisions_acte, as: :text
      f.input :objet, as: :text
    end

    f.inputs 'Autres champs' do
      f.input :services_votes, as: :boolean
      f.input :liste_actes, as: :boolean
      f.input :nombre_actes, as: :number
      f.input :renvoie_instruction, as: :boolean
      f.input :pdf_generation_status
      f.input :sheet_data
    end

    f.actions
  end

  # Page de détail
  show do
    attributes_table do
      row :id
      row :numero_formate
      row :numero_utilisateur
      row :type_acte
      row :etat
      row :perimetre
      row :categorie_organisme
      row :user
      row :annee

      row :numero_chorus
      row :numero_tf
      row :numero_marche

      row :date_chorus
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
      row :sous_action
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

      row :type_observations do |acte|
        acte.type_observations.join(', ') if acte.type_observations.present?
      end
      row :observations
      row :precisions_acte
      row :objet

      row :pre_instruction
      row :services_votes
      row :liste_actes
      row :nombre_actes
      row :renvoie_instruction
      row :pdf_generation_status

      row :created_at
      row :updated_at
    end

    panel 'Suspensions' do
      table_for ht2_acte.suspensions do
        column :id
        column :date_suspension
        column :date_reprise
        column :motif
        column :observations
        column :created_at
      end
    end

    panel 'Écheanciers' do
      table_for ht2_acte.echeanciers do
        column :id
        column :annee
        column :montant_ae
        column :montant_cp
      end
    end

    panel 'Lignes de poste' do
      table_for ht2_acte.poste_lignes do
        column :id
        column :numero
        column :centre_financier_code
        column :montant
        column :domaine_fonctionnel
        column :fonds
        column :compte_budgetaire
        column :code_activite
      end
    end

    active_admin_comments
  end
end
