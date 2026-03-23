ActiveAdmin.register PosteLigne do

  permit_params :ht2_acte_id, :numero, :centre_financier_code, :numero_tf, :montant,
                :domaine_fonctionnel, :fonds, :compte_budgetaire, :code_activite,
                :axe_ministeriel, :groupe_marchandises, :flux

  index do
    selectable_column
    id_column
    column(:ht2_acte) { |p| p.ht2_acte_id }
    column :numero
    column :centre_financier_code
    column :numero_tf
    column :montant
    column :domaine_fonctionnel
    column :fonds
    column :compte_budgetaire
    column :code_activite
    column :axe_ministeriel
    column :groupe_marchandises
    column :flux
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:ht2_acte) { |p| p.ht2_acte_id }
      row :numero
      row :centre_financier_code
      row :numero_tf
      row :montant
      row :domaine_fonctionnel
      row :fonds
      row :compte_budgetaire
      row :code_activite
      row :axe_ministeriel
      row :groupe_marchandises
      row :flux
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :ht2_acte, as: :select,
              collection: Ht2Acte.order(:id).map { |a| [a.id, a.id] }
      f.input :numero
      f.input :centre_financier_code
      f.input :numero_tf
      f.input :montant, as: :number, step: 0.01
      f.input :domaine_fonctionnel
      f.input :fonds
      f.input :compte_budgetaire
      f.input :code_activite
      f.input :axe_ministeriel
      f.input :groupe_marchandises
      f.input :flux
    end
    f.actions
  end

end
