Rails.application.routes.draw do
  	scope(:path => '/anaco') do
	    devise_for :users, :path => "",
	      :path_names =>  {:sign_in => "connexion", :sign_out => "logout"},
	      controllers: {sessions: 'sessions'}

		root "pages#index"
		get 'utilisateurs' => "users#index"
    	post 'import_users' => "users#import"
    	post '/select_nom' => 'users#select_nom'

    	resources :bops, only: [:index, :show]    	
    	get '/ajout_bops' => "bops#new"
    	post 'import_bops' => "bops#import"

    	get 'historique' => "avis#index"
      get 'consultation' => "avis#consultation"
    	get 'avis/nouveau/:bop_id' => "avis#new"
      post 'read_avis' => "avis#readAvis"
    	resources :avis, only: [:create, :update, :destroy]
      post 'open_modal' => "avis#openModal"

      get '/restitutions', to: "pages#restitutions"
			get '/restitutions/:programme', to: "pages#restitution_programme"
      post 'filter_restitution', to: "pages#filter_restitution"
	  	get '/mentions-legales', to: 'pages#mentions_legales'
	    get '/donnees-personnelles', to: 'pages#donnees_personnelles'
	    get '/accessibilite', to: 'pages#accessibilite'
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
