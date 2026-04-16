ActiveAdmin.register Bop do

  permit_params :user_id, :dcb_id, :programme_id, :code, :dotation, :deconcentre, :statut

  index do
    selectable_column
    id_column
    column :code
    column(:programme) { |b| "#{b.programme.numero} - #{b.programme.nom}" }
    column(:ministere) { |b| b.programme.ministere.nom }
    column :statut
    column :dotation
    column :deconcentre
    column(:user) { |b| b.user.nom }
    column(:dcb) { |b| b.dcb.nom }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :code
      row(:programme) { |b| "#{b.programme.numero} - #{b.programme.nom}" }
      row(:ministere) { |b| b.programme.ministere.nom }
      row :statut
      row :dotation
      row :deconcentre
      row(:user) { |b| b.user.nom }
      row(:dcb) { |b| b.dcb.nom }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :code
      f.input :statut, as: :select, collection: ["actif", "inactif"]
      f.input :dotation, as: :select, collection: ["HT2", "T2", "HT2 et T2"]
      f.input :deconcentre, as: :boolean
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :dcb_id, as: :select, label: "DCB",
              collection: User.order(:nom).map { |u| [u.nom, u.id] }
    end
    f.actions
  end

end
