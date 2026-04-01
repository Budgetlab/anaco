ActiveAdmin.register User do

  permit_params :email, :password, :password_confirmation, :statut, :nom

  index do
    selectable_column
    id_column
    column :nom
    column :email
    column :statut
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :nom
      row :email
      row :statut
      row :reset_password_sent_at
      row :remember_created_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :nom
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :statut, as: :select, collection: ["admin", "CBR", "DCB"]
    end
    f.actions
  end

end
