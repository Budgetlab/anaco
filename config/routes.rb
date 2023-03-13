Rails.application.routes.draw do
  	scope(:path => '/anaco') do
	    devise_for :users, :path => "",
	      :path_names =>  {:sign_in => "connexion", :sign_out => "logout"},
	      controllers: {sessions: 'sessions'}

		root "pages#index"
		get 'utilisateurs' => "users#index"
    	post 'import_users' => "users#import"
			post 'import2_users' => "users#import2"
    	post '/select_nom' => 'users#select_nom'

    	resources :bops do
        resources :avis, only: [:new]
			end
      post 'import_bops' => "bops#import"

    	get 'historique' => "avis#index"
      get 'consultation' => "avis#consultation"
      #get 'avis/nouveau/:bop_id' => "avis#new"
      #post 'read_avis' => "avis#readAvis"
    	resources :avis, only: [:create, :update, :destroy, :update]
      post 'open_modal' => "avis#openModal"
			post 'filter_consultation', to: "avis#filter_consultation"
			post 'filter_historique', to: "avis#filter_historique"
      post 'reset', to: "avis#reset"
      post 'reset_brouillon', to: "avis#reset_brouillon"

      post "filter_bop", to: "bops#filter_bop"

      get '/restitutions', to: "pages#restitutions"
			get '/restitutions/:programme', to: "pages#restitution_programme"
      post 'filter_restitution', to: "pages#filter_restitution"

      get '/mentions-legales', to: 'pages#mentions_legales'
	    get '/donnees-personnelles', to: 'pages#donnees_personnelles'
	    get '/accessibilite', to: 'pages#accessibilite'
			get '/plan', to: 'pages#plan'
			get '/faq', to: 'pages#faq'
	    get '/*path', to: 'pages#error_404'
	    get '/page_introuvable', to: 'pages#error_404'
	    match "/404", to: 'pages#error_404', via: :all
	    match "/500", to: 'pages#error_500', via: :all
	    get "/422", to: 'pages#error_404'
	end
	get '/', to: redirect('/anaco')
  	get '/500', to: redirect('/anaco/500')
  	get '/*path', to: redirect('/anaco')
end
