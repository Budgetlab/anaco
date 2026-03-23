ActiveAdmin.register Programme do

  permit_params :numero, :nom, :user_id, :dotation, :statut, :mission_id,
                :ministere_id, :date_inactivite, :deconcentre

  index do
    selectable_column
    id_column
    column :numero
    column :nom
    column :dotation
    column :statut
    column :deconcentre
    column(:mission) { |p| p.mission_id }
    column(:ministere) { |p| p.ministere_id }
    column(:user) { |p| p.user_id }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :numero
      row :nom
      row :dotation
      row :statut
      row :deconcentre
      row(:mission) { |p| p.mission_id }
      row(:ministere) { |p| p.ministere_id }
      row(:user) { |p| p.user_id }
      row :date_inactivite
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :numero
      f.input :nom
      f.input :dotation, as: :select, collection: ["HT2", "T2", "HT2 et T2"]
      f.input :statut, as: :select, collection: ["Actif", "Inactif"]
      f.input :deconcentre, as: :boolean
      f.input :mission, as: :select, collection: Mission.order(:nom).map { |m| [m.nom, m.id] }
      f.input :ministere, as: :select, collection: Ministere.order(:nom).map { |m| [m.nom, m.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :date_inactivite, as: :datepicker
    end
    f.actions
  end

end
