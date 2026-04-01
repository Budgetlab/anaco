ActiveAdmin.register CentreFinancier do

  permit_params :bop_id, :code, :programme_id, :deconcentre, :statut

  index do
    selectable_column
    id_column
    column :code
    column :statut
    column :deconcentre
    column(:bop) { |c| c.bop_id }
    column(:programme) { |c| c.programme_id }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :code
      row :statut
      row :deconcentre
      row(:bop) { |c| c.bop_id }
      row(:programme) { |c| c.programme_id }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :code
      f.input :statut, as: :select, collection: ["Actif", "non valide"]
      f.input :deconcentre, as: :boolean
      f.input :bop, as: :select,
              collection: Bop.order(:code).map { |b| [b.code, b.id] },
              include_blank: true
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] },
              include_blank: true
    end
    f.actions
  end

end
