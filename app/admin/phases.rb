ActiveAdmin.register Phase do

  menu label: "Phases", priority: 5

  permit_params :nom, :annee, :date_debut

  filter :annee
  filter :nom, as: :select, collection: Phase::NOMS_CONNUS
  filter :date_debut

  index do
    selectable_column
    id_column
    column :annee
    column :nom
    column :date_debut
    column("Numéro") { |p| p.numero_dans_annee }
    column("Libellé affiché") { |p| p.libelle_avec_numero }
    column("Avis associés") { |p| p.avis.count }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :annee
      row :nom
      row :date_debut
      row("Numéro dans l'année") { |p| p.numero_dans_annee }
      row("Libellé affiché") { |p| p.libelle_avec_numero }
      row("Nombre d'avis associés") { |p| p.avis.count }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :annee, as: :number,
              hint: "Année budgétaire à laquelle la phase appartient (ex: 2026)."
      f.input :nom, as: :select, collection: Phase::NOMS_CONNUS,
              include_blank: false,
              hint: "Nom de la phase. Plusieurs lignes avec le même nom dans une année sont admises (ex: services votés V1 et V2) — elles seront numérotées automatiquement."
      f.input :date_debut, as: :datepicker,
              hint: "Date d'ouverture de la phase. Doit être dans l'année renseignée."
    end
    f.actions
  end

end
