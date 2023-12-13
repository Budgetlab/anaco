Rails.application.routes.draw do
  scope(:path => '/anaco') do
  devise_for :users, :path => '',
    :path_names =>  {:sign_in => 'connexion', :sign_out => 'logout'},
    controllers: {sessions: 'sessions'}

  root 'pages#index'
  get 'utilisateurs' => 'users#index'
  post 'import_users' => 'users#import'
  post 'import_nom_users' => 'users#import_nom'
  post '/select_nom' => 'users#select_nom'

  resources :bops do
    resources :avis, only: [:new]
  end
  post 'import_bops' => 'bops#import'
  post 'filter_bop', to: 'bops#filter_bop'

  resources :programmes do
    resources :credits, only: [:new]
  end
  resources :credits, only: [:index, :create, :update, :destroy]
  post 'import_programmes' => 'programmes#import'
  get 'credits_suivi' => 'credits#suivi'
  post 'filter_credits', to: 'credits#filter_credits'
  post 'open_modal_credit' => 'credits#open_modal_credit'

  get 'historique' => 'avis#index'
  get 'consultation' => 'avis#consultation'
  resources :avis, only: [:create, :update, :destroy]
  post 'open_modal' => 'avis#open_modal'
  post 'open_modal_brouillon' => 'avis#open_modal_brouillon'
  post 'filter_consultation', to: 'avis#filter_consultation'
  post 'filter_historique', to: 'avis#filter_historique'
  post 'reset_brouillon', to: 'avis#reset_brouillon'
  post 'update_etat', to: 'avis#update_etat'
  get 'ajout_avis', to: 'avis#ajout_avis'
  post 'import_avis', to: 'avis#import'

  get '/restitutions', to: 'pages#restitutions'
  get '/restitutions/:programme', to: 'pages#restitution_programme', as: 'specific_restitutions'
  post 'filter_restitution', to: 'pages#filter_restitution'
  get 'suivi', to: "pages#suivi"

  get '/mentions-legales', to: 'pages#mentions_legales'
  get '/donnees-personnelles', to: 'pages#donnees_personnelles'
  get '/accessibilite', to: 'pages#accessibilite'
  get '/plan', to: 'pages#plan'
  get '/faq', to: 'pages#faq'
  #routes pages erreurs
  match '/500', via: :all, to: 'errors#error_500'
  match '/404', via: :all, to: 'errors#error_404'
  match '/503', via: :all, to: 'errors#error_503'
  match '*path', to: 'errors#error_404', via: :all
end
  get '/', to: redirect('/anaco')
  #get '/500', to: redirect('/anaco/500')
  #get '/*path', to: redirect('/anaco')
end
