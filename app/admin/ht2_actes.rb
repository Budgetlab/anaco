ActiveAdmin.register Ht2Acte do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code, :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte, :pre_instruction, :action, :sous_action, :activite, :lien_tf, :numero_tf, :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation, :proposition_decision, :commentaire_proposition_decision, :complexite, :observations, :type_observations, :user_id, :valideur, :decision_finale
  #
  # or
  #
  # permit_params do
  #   permitted = [:type_acte, :etat, :instructeur, :nature, :montant_ae, :montant_global, :centre_financier_code, :date_chorus, :numero_chorus, :beneficiaire, :objet, :ordonnateur, :precisions_acte, :pre_instruction, :action, :sous_action, :activite, :lien_tf, :numero_tf, :disponibilite_credits, :imputation_depense, :consommation_credits, :programmation, :proposition_decision, :commentaire_proposition_decision, :complexite, :observations, :type_observations, :user_id, :valideur, :decision_finale]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
