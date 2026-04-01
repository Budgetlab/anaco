ActiveAdmin.register Suspension do

  MOTIFS_SUSPENSION = [
    "Autre",
    "Défaut du circuit d'approbation Chorus",
    "Demande d'éléments complémentaires",
    "Demande de mise en cohérence EJ /PJ",
    "Demande de précisions",
    "Erreur d'imputation",
    "Erreur dans la construction de l'EJ",
    "Mauvaise évaluation de la consommation des crédits",
    "Non conformité des pièces",
    "Pièce(s) manquante(s)",
    "Problématique de compatibilité avec la programmation",
    "Problématique de disponibilité des crédits",
    "Problématique de soutenabilité",
    "Saisine a posteriori",
  ].freeze

  permit_params :ht2_acte_id, :date_suspension, :date_reprise, :observations, :commentaire_reprise, motif: []

  before_action only: [:create, :update] do
    params[:suspension][:motif]&.reject!(&:blank?)
  end

  index do
    selectable_column
    id_column
    column :ht2_acte
    column :date_suspension
    column :date_reprise
    column :motif do |s|
      s.motif.join(", ")
    end
    column :observations
    column :commentaire_reprise
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :ht2_acte
      row :date_suspension
      row :date_reprise
      row :motif do |s|
        s.motif.join(", ")
      end
      row :observations
      row :commentaire_reprise
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :ht2_acte, as: :select, collection: Ht2Acte.order(:id).map { |a| [a.id, a.id] }
      f.input :date_suspension, as: :datepicker
      f.input :date_reprise, as: :datepicker
      f.input :motif, as: :check_boxes, collection: MOTIFS_SUSPENSION, multiple: true
      f.input :observations, as: :text
      f.input :commentaire_reprise, as: :text
    end
    f.actions
  end

end
