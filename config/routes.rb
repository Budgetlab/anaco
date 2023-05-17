Rails.application.routes.draw do
  scope(:path => '/anaco') do
  devise_for :users, :path => '',
    :path_names =>  {:sign_in => 'connexion', :sign_out => 'logout'},
    controllers: {sessions: 'sessions'}

  root 'pages#index'
  get 'utilisateurs' => 'users#index'
  post 'import_users' => 'users#import'
  post 'import2_users' => 'users#import2'
  post '/select_nom' => 'users#select_nom'

  resources :bops do
    resources :avis, only: [:new]
  end
  post 'import_bops' => 'bops#import'
	post 'filter_bop', to: 'bops#filter_bop'

  get 'historique' => 'avis#index'
  get 'consultation' => 'avis#consultation'
  resources :avis, only: [:create, :update, :destroy, :update]
  post 'open_modal' => 'avis#openModal'
  post 'filter_consultation', to: 'avis#filter_consultation'
  post 'filter_historique', to: 'avis#filter_historique'
  post 'reset', to: 'avis#reset'
  post 'reset_brouillon', to: 'avis#reset_brouillon'

  get '/restitutions', to: 'pages#restitutions'
  get '/restitutions/:programme', to: 'pages#restitution_programme'
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
end
  get '/', to: redirect('/anaco')
  #get '/500', to: redirect('/anaco/500')
  #get '/*path', to: redirect('/anaco')
end
