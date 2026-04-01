ActiveAdmin.register Bop do

  permit_params :user_id, :dcb_id, :programme_id, :ministere, :numero_programme,
                :nom_programme, :code, :dotation, :deconcentre

  index do
    selectable_column
    id_column
    column :code
    column :numero_programme
    column :nom_programme
    column :dotation
    column :deconcentre
    column :ministere
    column(:programme) { |b| b.programme_id }
    column(:user) { |b| b.user_id }
    column(:dcb) { |b| b.dcb_id }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :code
      row :numero_programme
      row :nom_programme
      row :dotation
      row :deconcentre
      row :ministere
      row(:programme) { |b| b.programme_id }
      row(:user) { |b| b.user_id }
      row(:dcb) { |b| b.dcb_id }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :code
      f.input :numero_programme, as: :number
      f.input :nom_programme
      f.input :dotation, as: :select, collection: ["HT2", "T2", "HT2 et T2"]
      f.input :deconcentre, as: :boolean
      f.input :ministere
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :dcb_id, as: :select, label: "DCB",
              collection: User.order(:nom).map { |u| [u.nom, u.id] }
    end
    f.actions
  end

end
