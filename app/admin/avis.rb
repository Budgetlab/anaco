ActiveAdmin.register Avi do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :phase, :date_reception, :date_envoi, :is_delai, :is_crg1, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :statut, :etat, :commentaire, :bop_id, :user_id, :annee
  #
  # or
  #
  # permit_params do
  #   permitted = [:phase, :date_reception, :date_envoi, :is_delai, :is_crg1, :ae_i, :cp_i, :t2_i, :etpt_i, :ae_f, :cp_f, :t2_f, :etpt_f, :statut, :etat, :commentaire, :bop_id, :user_id, :annee]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
