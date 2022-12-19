Rails.application.routes.draw do
  	scope(:path => '/avisbop') do
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
    	get 'avis/nouveau/:bop_id' => "avis#new"
    	resources :avis, only: [:create, :update, :destroy]

	  	get '/mentions-legales', to: 'pages#mentions_legales'
	    get '/donnees-personnelles', to: 'pages#donnees_personnelles'
	    get '/accessibilite', to: 'pages#accessibilite'
	    get '/*path', to: 'pages#error_404'
	    get '/page_introuvable', to: 'pages#error_404'
	    match "/404", to: 'pages#error_404', via: :all
	    match "/500", to: 'pages#error_500', via: :all
	    get "/422", to: 'pages#error_404'
	end
	get '/', to: redirect('/avisbop')
  	get '/500', to: redirect('/avisbop/500')
  	get '/*path', to: redirect('/avisbop')
end
