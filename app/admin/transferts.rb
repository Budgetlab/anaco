ActiveAdmin.register Transfert do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :gestion_schema_id, :nature, :montant_ae, :montant_cp, :programme_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:gestion_schema_id, :nature, :montant_ae, :montant_cp, :programme_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
