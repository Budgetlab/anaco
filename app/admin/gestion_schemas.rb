ActiveAdmin.register GestionSchema do

  permit_params :programme_id, :user_id, :schema_id, :vision, :profil, :annee,
                :ressources_ae, :ressources_cp, :depenses_ae, :depenses_cp,
                :mer_ae, :mer_cp, :surgel_ae, :surgel_cp,
                :mobilisation_mer_ae, :mobilisation_mer_cp,
                :mobilisation_surgel_ae, :mobilisation_surgel_cp,
                :fongibilite_ae, :fongibilite_cp, :fongibilite_cas, :fongibilite_hcas,
                :decret_ae, :decret_cp,
                :credits_lfg_ae, :credits_lfg_cp,
                :reports_ae, :reports_cp,
                :reports_autre_ae, :reports_autre_cp,
                :charges_a_payer_ae, :charges_a_payer_cp,
                :credits_reports_ae, :credits_reports_cp,
                :commentaire

  index do
    selectable_column
    id_column
    column(:programme) { |g| g.programme_id }
    column(:user) { |g| g.user_id }
    column(:schema) { |g| g.schema_id }
    column :annee
    column :vision
    column :profil
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row(:programme) { |g| g.programme_id }
      row(:user) { |g| g.user_id }
      row(:schema) { |g| g.schema_id }
      row :annee
      row :vision
      row :profil
      row :ressources_ae
      row :ressources_cp
      row :depenses_ae
      row :depenses_cp
      row :mer_ae
      row :mer_cp
      row :surgel_ae
      row :surgel_cp
      row :mobilisation_mer_ae
      row :mobilisation_mer_cp
      row :mobilisation_surgel_ae
      row :mobilisation_surgel_cp
      row :fongibilite_ae
      row :fongibilite_cp
      row :fongibilite_cas
      row :fongibilite_hcas
      row :decret_ae
      row :decret_cp
      row :credits_lfg_ae
      row :credits_lfg_cp
      row :reports_ae
      row :reports_cp
      row :reports_autre_ae
      row :reports_autre_cp
      row :charges_a_payer_ae
      row :charges_a_payer_cp
      row :credits_reports_ae
      row :credits_reports_cp
      row :commentaire
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs 'Références' do
      f.input :programme, as: :select,
              collection: Programme.order(:numero).map { |p| ["#{p.numero} - #{p.nom}", p.id] }
      f.input :user, as: :select, collection: User.order(:nom).map { |u| [u.nom, u.id] }
      f.input :schema, as: :select,
              collection: Schema.order(:id).map { |s| ["Schema #{s.id} - #{s.annee}", s.id] }
      f.input :annee, as: :number
      f.input :vision
      f.input :profil
    end
    f.inputs 'Ressources / Dépenses' do
      f.input :ressources_ae, as: :number, step: 0.01
      f.input :ressources_cp, as: :number, step: 0.01
      f.input :depenses_ae, as: :number, step: 0.01
      f.input :depenses_cp, as: :number, step: 0.01
    end
    f.inputs 'MER / Surgel' do
      f.input :mer_ae, as: :number, step: 0.01
      f.input :mer_cp, as: :number, step: 0.01
      f.input :surgel_ae, as: :number, step: 0.01
      f.input :surgel_cp, as: :number, step: 0.01
      f.input :mobilisation_mer_ae, as: :number, step: 0.01
      f.input :mobilisation_mer_cp, as: :number, step: 0.01
      f.input :mobilisation_surgel_ae, as: :number, step: 0.01
      f.input :mobilisation_surgel_cp, as: :number, step: 0.01
    end
    f.inputs 'Fongibilité / Décrets' do
      f.input :fongibilite_ae, as: :number, step: 0.01
      f.input :fongibilite_cp, as: :number, step: 0.01
      f.input :fongibilite_cas, as: :number, step: 0.01
      f.input :fongibilite_hcas, as: :number, step: 0.01
      f.input :decret_ae, as: :number, step: 0.01
      f.input :decret_cp, as: :number, step: 0.01
    end
    f.inputs 'Crédits / Reports' do
      f.input :credits_lfg_ae, as: :number, step: 0.01
      f.input :credits_lfg_cp, as: :number, step: 0.01
      f.input :reports_ae, as: :number, step: 0.01
      f.input :reports_cp, as: :number, step: 0.01
      f.input :reports_autre_ae, as: :number, step: 0.01
      f.input :reports_autre_cp, as: :number, step: 0.01
      f.input :charges_a_payer_ae, as: :number, step: 0.01
      f.input :charges_a_payer_cp, as: :number, step: 0.01
      f.input :credits_reports_ae, as: :number, step: 0.01
      f.input :credits_reports_cp, as: :number, step: 0.01
    end
    f.inputs 'Commentaire' do
      f.input :commentaire, as: :text
    end
    f.actions
  end

end
