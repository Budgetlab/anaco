ActiveAdmin.register Avi do

  permit_params :phase, :date_reception, :date_envoi, :is_delai, :is_crg1,
                :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f,
                :statut, :etat, :commentaire, :bop_id, :user_id, :annee, :duree_prevision

  index do
    selectable_column
    id_column
    column(:bop) { |a| a.bop_id }
    column(:user) { |a| a.user_id }
    column :phase
    column :annee
    column :statut
    column :etat
    column :date_reception
    column :date_envoi
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:bop) { |a| a.bop_id }
      row(:user) { |a| a.user_id }
      row :phase
      row :annee
      row :statut
      row :etat
      row :is_delai
      row :is_crg1
      row :duree_prevision
      row :date_reception
      row :date_envoi
      row :ae_i
      row :cp_i
      row :t2_i
      row :etpt_i
      row :ae_f
      row :cp_f
      row :t2_f
      row :etpt_f
      row :commentaire
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :bop, as: :select, collection: Bop.order(:code).map { |b| [b.code, b.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :phase, as: :select, collection: ["début de gestion", "services votés", "fin de gestion"]
      f.input :annee, as: :number
      f.input :statut
      f.input :etat
      f.input :is_delai, as: :boolean
      f.input :is_crg1, as: :boolean
      f.input :duree_prevision, as: :number
      f.input :date_reception, as: :datepicker
      f.input :date_envoi, as: :datepicker
      f.input :ae_i, as: :number, step: 0.01
      f.input :cp_i, as: :number, step: 0.01
      f.input :t2_i, as: :number, step: 0.01
      f.input :etpt_i, as: :number, step: 0.01
      f.input :ae_f, as: :number, step: 0.01
      f.input :cp_f, as: :number, step: 0.01
      f.input :t2_f, as: :number, step: 0.01
      f.input :etpt_f, as: :number, step: 0.01
      f.input :commentaire, as: :text
    end
    f.actions
  end

end
