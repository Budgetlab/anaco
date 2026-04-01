ActiveAdmin.register Transfert do

  permit_params :gestion_schema_id, :nature, :montant_ae, :montant_cp, :programme_id

  index do
    selectable_column
    id_column
    column(:gestion_schema) { |t| t.gestion_schema_id }
    column(:programme) { |t| t.programme_id }
    column :nature
    column :montant_ae
    column :montant_cp
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:gestion_schema) { |t| t.gestion_schema_id }
      row(:programme) { |t| t.programme_id }
      row :nature
      row :montant_ae
      row :montant_cp
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :gestion_schema, as: :select,
              collection: GestionSchema.order(:id).map { |g| [g.id, g.id] }
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] }
      f.input :nature
      f.input :montant_ae, as: :number, step: 0.01
      f.input :montant_cp, as: :number, step: 0.01
    end
    f.actions
  end

end
