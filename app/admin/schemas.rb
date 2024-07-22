ActiveAdmin.register Schema do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :programme_id, :user_id, :statut, :annee
  #
  # or
  #
  # permit_params do
  #   permitted = [:programme_id, :user_id, :statut, :annee]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
