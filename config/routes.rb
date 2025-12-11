Rails.application.routes.draw do
  get "suspensions/edit"
  get "suspensions/update"
  get "suspensions/destroy"
  scope(:path => '/anaco') do
    # 1. Routes Active Storage (montées manuellement ici) #Attention enlever match 404 si on eleve ces routes
    #scope '/rails/active_storage' do
    #  get '/blobs/redirect/:signed_id/*filename', to: 'active_storage/blobs/redirect#show', as: :rails_service_blob
    #  get '/blobs/proxy/:signed_id/*filename', to: 'active_storage/blobs/proxy#show', as: :rails_service_blob_proxy
    #  get '/blobs/:signed_id/*filename', to: 'active_storage/blobs/redirect#show'
    #  get '/representations/redirect/:signed_blob_id/:variation_key/*filename', to: 'active_storage/representations/redirect#show', as: :rails_blob_representation
    #  get '/representations/proxy/:signed_blob_id/:variation_key/*filename', to: 'active_storage/representations/proxy#show', as: :rails_blob_representation_proxy
    #  get '/representations/:signed_blob_id/:variation_key/*filename', to: 'active_storage/representations/redirect#show'
    #  get '/disk/:encoded_key/*filename', to: 'active_storage/disk#show', as: :rails_disk_service
    #  put '/disk/:encoded_token', to: 'active_storage/disk#update', as: :update_rails_disk_service
    #  post '/direct_uploads', to: 'active_storage/direct_uploads#create', as: :rails_direct_uploads
    #end

    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
    devise_for :users, :path => '',
               :path_names => { :sign_in => 'connexion', :sign_out => 'logout' },
               controllers: { sessions: 'sessions' }

    root 'pages#index'
    get 'global_search', to: 'pages#global_search'
    get 'utilisateurs' => 'users#index'
    post 'import_users' => 'users#import'
    post '/select_nom' => 'users#select_nom'

    get 'suivi_remplissage_schemas', to: 'users#suivi_remplissage_schemas'

    resources :bops do
      resources :avis, only: [:new, :create, :edit, :update]
    end
    post 'import_bops' => 'bops#import'
    post 'filter_bop', to: 'bops#filter_bop'

    resources :missions
    resources :ministeres

    # resources :gestion_schemas, except: [:new, :create]
    resources :schemas, except: [:new, :create] do
      resources :gestion_schemas
      member do
        get 'confirm_delete' => "schemas#confirm_delete"
        get 'pdf_vision' => "schemas#pdf_vision"
      end
    end
    get 'schemas_remplissage' => "schemas#schemas_remplissage"
    get 'generate_schemas_pdf' => "schemas#generate_schemas_pdf"

    resources :programmes do
      resources :schemas, only: [:new, :create]
      member do
        get 'last_schema', to: 'programmes#show_last_schema'
        get 'avis', to: 'programmes#show_avis'
      end
    end
    post 'import_programmes' => 'programmes#import'

    resources :avis, only: :show
    get 'historique' => 'avis#index'
    get 'consultation' => 'avis#consultation'
    get 'remplissage_avis' => 'avis#remplissage_avis'
    get 'suivi_remplissage_avis' => 'avis#suivi_remplissage'
    get 'restitutions' => 'avis#restitutions'
    get 'restitutions_perimetre' => 'avis#restitutions_perimetre'
    post 'update_etat', to: 'avis#update_etat'
    get 'ajout_avis', to: 'avis#ajout_avis'
    post 'import_avis', to: 'avis#import'

    resources :ht2_actes do
      resources :suspensions do
        post :refus_suspension
        get :modal_delete
      end
      collection do
        post :bulk_cloture
        get 'tableau_de_bord', to: 'ht2_actes#tableau_de_bord'
        get 'synthese_temporelle', to: 'ht2_actes#synthese_temporelle'
        get 'synthese_anomalies', to: 'ht2_actes#synthese_anomalies'
        get 'synthese_suspensions', to: 'ht2_actes#synthese_suspensions'
      end
      member do
        get :export
        get :download_attachments
      end
    end
    get 'new_modal_acte', to: 'ht2_actes#new_modal', as: 'new_modal_acte'
    get 'show_modal_acte/:id', to: 'ht2_actes#show_modal', as: 'show_modal_acte'
    get 'modal_delete_acte/:id', to: 'ht2_actes#modal_delete', as: 'modal_delete_acte'
    get 'modal_pre_instruction/:id', to: 'ht2_actes#modal_pre_instruction', as: 'modal_pre_instruction'
    get 'modal_cloture_preinstruction_acte/:id', to: 'ht2_actes#modal_cloture_preinstruction', as: 'modal_cloture_preinstruction_acte'
    get 'renvoie_instruction/:id', to: 'ht2_actes#renvoie_instruction', as: 'renvoie_instruction'
    get 'modal_renvoie_validation/:id', to: 'ht2_actes#modal_renvoie_validation', as: 'modal_renvoie_validation'
    get 'validate_acte/:id', to: 'ht2_actes#validate_acte', as: 'validate_acte'
    get 'acte_actions/:id', to: 'ht2_actes#acte_actions', as: 'acte_actions'
    post 'cloture_pre_instruction/:id', to: 'ht2_actes#cloture_pre_instruction', as: 'cloture_pre_instruction'
    get 'check_chorus_number', to: 'ht2_actes#check_chorus_number'
    get 'synthese_ht2_actes', to: 'ht2_actes#synthese'
    get 'synthese_users_ht2_actes', to: 'ht2_actes#synthese_utilisateurs'
    get 'historique_ht2', to: 'ht2_actes#historique'
    get 'ajout_actes', to: 'ht2_actes#ajout_actes'
    post 'import_actes', to: 'ht2_actes#import'

    resources :centre_financiers, only: [:new]
    post 'import_cf', to: 'centre_financiers#import'
    get '/centre_financiers/autocomplete', to: 'centre_financiers#autocomplete'

    get '/mentions-legales', to: 'pages#mentions_legales'
    get '/donnees-personnelles', to: 'pages#donnees_personnelles'
    get '/accessibilite', to: 'pages#accessibilite'
    get '/plan', to: 'pages#plan'
    get '/faq', to: 'pages#faq'
    # routes pages erreurs
    match '/500', via: :all, to: 'errors#error_500'
    match '/404', via: :all, to: 'errors#error_404'
    match '/503', via: :all, to: 'errors#error_503'
    #match '*path', to: 'errors#error_404', via: :all #commenté car sinon pb routes pour active storage loadé apres 404 et renvoie automatiquement vers 404
  end
  get '/', to: redirect('/anaco')
  # get '/500', to: redirect('/anaco/500')
  # get '/*path', to: redirect('/anaco')
end
