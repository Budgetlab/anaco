Rails.application.routes.draw do
  scope(:path => '/anaco') do
    devise_for :admin_users, ActiveAdmin::Devise.config
    ActiveAdmin.routes(self)
    devise_for :users, :path => '',
               :path_names => { :sign_in => 'connexion', :sign_out => 'logout' },
               controllers: { sessions: 'sessions' }

    root 'pages#index'
    get 'global_search', to: 'pages#global_search'
    get 'utilisateurs' => 'users#index'
    post 'import_users' => 'users#import'
    post 'import_nom_users' => 'users#import_nom'
    post '/select_nom' => 'users#select_nom'

    resources :bops do
      resources :avis, only: [:new]
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

    resources :programmes do
      resources :schemas, only: [:new, :create]
      member do
        get 'last_schema', to: 'programmes#show_last_schema'
        get 'avis', to: 'programmes#show_avis'
      end
    end
    post 'import_programmes' => 'programmes#import'

    get 'historique' => 'avis#index'
    get 'consultation' => 'avis#consultation'
    resources :avis, only: [:create, :update, :destroy]
    get 'remplissage_avis' => 'avis#remplissage_avis'
    get 'suivi_remplissage_avis' => 'avis#suivi_remplissage'
    get 'restitutions' => 'avis#restitutions'
    post 'open_modal' => 'avis#open_modal'
    post 'open_modal_brouillon' => 'avis#open_modal_brouillon'
    post 'reset_brouillon', to: 'avis#reset_brouillon'
    post 'update_etat', to: 'avis#update_etat'
    get 'ajout_avis', to: 'avis#ajout_avis'
    post 'import_avis', to: 'avis#import'

    get '/mentions-legales', to: 'pages#mentions_legales'
    get '/donnees-personnelles', to: 'pages#donnees_personnelles'
    get '/accessibilite', to: 'pages#accessibilite'
    get '/plan', to: 'pages#plan'
    get '/faq', to: 'pages#faq'
    # routes pages erreurs
    match '/500', via: :all, to: 'errors#error_500'
    match '/404', via: :all, to: 'errors#error_404'
    match '/503', via: :all, to: 'errors#error_503'
    match '*path', to: 'errors#error_404', via: :all
  end
  get '/', to: redirect('/anaco')
  # get '/500', to: redirect('/anaco/500')
  # get '/*path', to: redirect('/anaco')
end
