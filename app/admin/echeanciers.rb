ActiveAdmin.register Echeancier do

  permit_params :ht2_acte_id, :annee, :montant_ae, :montant_cp

  index do
    selectable_column
    id_column
    column(:ht2_acte) { |e| e.ht2_acte_id }
    column :annee
    column :montant_ae
    column :montant_cp
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:ht2_acte) { |e| e.ht2_acte_id }
      row :annee
      row :montant_ae
      row :montant_cp
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :ht2_acte, as: :select,
              collection: Ht2Acte.order(:id).map { |a| [a.id, a.id] }
      f.input :annee, as: :number
      f.input :montant_ae, as: :number, step: 0.01
      f.input :montant_cp, as: :number, step: 0.01
    end
    f.actions
  end

end
