ActiveAdmin.register Organisme do

  permit_params :nom, :acronyme, :statut, :id_opera, :user_id

  index do
    selectable_column
    id_column
    column :nom
    column :acronyme
    column :id_opera
    column :statut
    column :user
    column :created_at
    actions
  end

  filter :nom
  filter :acronyme
  filter :id_opera
  filter :statut
  filter :user

  show do
    attributes_table do
      row :id
      row :nom
      row :acronyme
      row :id_opera
      row :statut
      row :user
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :nom
      f.input :acronyme
      f.input :id_opera
      f.input :statut, as: :select, collection: %w[actif inactif]
      f.input :user
    end
    f.actions
  end

end
