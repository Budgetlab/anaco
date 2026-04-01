ActiveAdmin.register Schema do

  permit_params :programme_id, :user_id, :statut, :annee

  index do
    selectable_column
    id_column
    column(:programme) { |s| s.programme_id }
    column(:user) { |s| s.user_id }
    column :annee
    column :statut
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:programme) { |s| s.programme_id }
      row(:user) { |s| s.user_id }
      row :annee
      row :statut
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :annee, as: :number
      f.input :statut
    end
    f.actions
  end

end
