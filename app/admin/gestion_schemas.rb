ActiveAdmin.register GestionSchema do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :programme_id, :user_id, :schema_id, :vision, :profil, :annee, :ressources_ae, :ressources_cp, :depenses_ae, :depenses_cp,:mer_ae, :mer_cp,:surgel_ae, :surgel_cp, :mobilisation_mer_ae, :mobilisation_mer_cp,:mobilisation_surgel_ae, :mobilisation_surgel_cp, :fongibilite_ae, :fongibilite_cp, :decret_ae, :decret_cp, :credits_ouverts_ae, :credits_lfg_ae, :credits_lfg_cp,:reports_ae, :reports_cp,:charges_a_payer_ae, :charges_a_payer_cp, :credits_reports_ae, :credits_reports_cp, :reports_autre_ae, :reports_autre_cp, :credits_reports_autre_ae, :credits_reports_autre_cp, :commentaire, :fongibilite_cas, :fongibilite_hcas
  #
  # or
  #
  # permit_params do
  #   permitted = [:programme_id, :user_id, :schema_id, :statut, :vision, :profil, :annee, :prevision_solde_budgetaire_ae, :prevision_solde_budgetaire_cp, :mer_ae, :mer_cp, :mobilisation_mer_ae, :mobilisation_mer_cp, :fongibilite_ae, :fongibilite_cp, :decret_ae, :decret_cp, :credits_ouverts_ae, :credits_ouverts_cp, :charges_a_payer_ae, :charges_a_payer_cp, :credits_reports_ae, :credits_reports_cp, :reports_autre_ae, :reports_autre_cp, :commentaire]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
