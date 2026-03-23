ActiveAdmin.register Mission do

  permit_params :nom

  index do
    selectable_column
    id_column
    column :nom
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :nom
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :nom
    end
    f.actions
  end

end
