Gemeinschaft42c::Application.routes.draw do

  # To-Do: Delete these two entries and remap path on the views.
  resources :pager_group_destinations
  resources :pager_groups

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      resources :switchboards, :only => [:show, :index]
      resources :switchboard_entries, :only => [:show, :index]
      resources :sip_accounts, :only => [:show, :index]
      resources :pager_groups
      resources :phone_numbers, :only => [:show, :index]
      resources :calls, :only => [:index, :show, :update]
      resources :phone_book_entries, :only => [:index]
    end

    resources :rows 
  end

  resources :generic_files

  resources :voicemail_accounts do
    resources :voicemail_settings
    resources :voicemail_messages do
      collection do
        delete 'destroy_multiple'
      end
      member do
        put 'call'
        put 'mark_read'
        put 'mark_unread'
      end
    end
  end

  resources :switchboards do
    resources :switchboard_entries do
      collection { post :sort }
    end
  end

  resources :restore_jobs

  resources :groups do
    resources :group_memberships
    resources :group_permissions
  end

  resources :sim_card_providers do
    resources :sim_cards, :except => [:edit, :update]
  end

  resources :intruders

  resources :backup_jobs, :except => [:edit, :update]

  scope :constraints => lambda{|req|%w(127.0.0.1).include? req.remote_addr} do
    get "trigger/voicemail"
    get "trigger/fax"
    match 'trigger/fax_has_been_sent/:id' => 'trigger#fax_has_been_sent'
    match 'trigger/sip_account_update/:id' => 'trigger#sip_account_update'
  end

  resources :call_routes do
    collection { 
      post :sort 
      get :show_variables
      get :test
    }
    resources :route_elements do
      collection { post :sort }
    end
  end

  resources :gateways do
    resources :gateway_settings
    resources :gateway_parameters
    resources :gateway_headers
  end

  resources :gs_parameters, :only => [:show, :index, :update, :edit]

  resources :automatic_call_distributors

  resources :gs_cluster_sync_log_entries

  resources :gs_nodes do
    member do
      get 'sync'
    end
  end

  resources :gui_functions


  resources :phone_numbers, :only => [:sort] do
    collection { post :sort }
  end

  resources :acd_agents do
    resources :phone_numbers
    member do
      get 'toggle'
    end
  end

  resources :automatic_call_distributors, :only => [] do
    resources :acd_agents
    resources :phone_numbers
    resources :call_forwards
  end

  resources :hunt_group_members, :only => [] do
    resources :phone_numbers
  end

  resources :hunt_groups, :only => [] do
    resources :hunt_group_members
    resources :phone_numbers
    resources :call_forwards
  end

  if GsParameter.get('CALLTHROUGH_HAS_WHITELISTS') == true
    resources :whitelists, :only => [] do
      resources :phone_numbers
    end
  end

  resources :access_authorizations, :only => [] do
    resources :phone_numbers
  end

  resources :fax_documents

  resources :fax_accounts, :only => [] do
    resources :fax_documents
    resources :phone_numbers
  end

  resources :gemeinschaft_setups, :only => [:new, :create]

  resources :phone_number_ranges, :only => [] do
    resources :phone_numbers
  end
  
  resources :conferences, :only => [] do
    resources :conference_invitees
    resources :phone_numbers
  end
  
  resources :phone_numbers, :only => [] do
    resources :call_forwards
    resources :ringtones
  end
  
  resources :addresses
  
  resources :sip_domains
  
  resources :manufacturers do
    resources :phone_models
  end
  
  # Log-in / log-out / sign-up:
  get "log_in"  => "sessions#new"     , :as => "log_in"  
  get "log_out" => "sessions#destroy" , :as => "log_out"  
  get "sign_up" => "users#new"        , :as => "sign_up"  
  get "login"   => "sessions#new"     , :as => "log_in"  
  get "logout"  => "sessions#destroy" , :as => "log_out"  
  get "signup"  => "users#new"        , :as => "sign_up"  
  
  # Provisioning:
  # Snom
  get "config_snom/:phone/:sip_account/idle_screen"        => "config_snom#idle_screen"
  get "config_snom/:phone/:sip_account/log_in"             => "config_snom#log_in"
  get "config_snom/:phone/:sip_account/phone_book"         => "config_snom#phone_book"
  get "config_snom/:phone/:sip_account/call_history"       => "config_snom#call_history"
  get "config_snom/:phone/:sip_account/call_history_:type" => "config_snom#call_history"
  get "config_snom/:phone/:sip_account/voicemail"          => "config_snom#voicemail"
  get "config_snom/:phone/:sip_account/call_forwarding"    => "config_snom#call_forwarding"
  get "config_snom/exit"                                   => "config_snom#exit"
  get "config_snom/:phone/exit"                            => "config_snom#exit"
  get "config_snom/:phone/:sip_account/exit"               => "config_snom#exit"
  get "config_snom/:phone/:sip_account/hunt_group"         => "config_snom#hunt_group"
  get "config_snom/:phone/state_settings"                  => "config_snom#state_settings"
  get "config_snom/:phone/log_out"                         => "config_snom#log_out"
  get "config_snom/:phone/:sip_account/log_out"            => "config_snom#log_out"
  get "config_snom/:phone/log_in"                          => "config_snom#log_in"
  get "config_snom/:phone/:sip_account/log_in"             => "config_snom#log_in"
  get "config_snom/:phone/:sip_account/acd"                => "config_snom#acd"

  # Siemens
  get "config_siemens/:phone/call_history"                 => "config_siemens#call_history"
  get "config_siemens/:phone/:sip_account/call_history"    => "config_siemens#call_history"
  get "config_siemens/:phone/:sip_account/call_forwarding" => "config_siemens#call_forwarding"
  get "config_siemens/:phone/hunt_group"                   => "config_siemens#hunt_group"
  get "config_siemens/:phone/:sip_account/hunt_group"      => "config_siemens#hunt_group"
  get "config_siemens/:phone/menu"                         => "config_siemens#menu"
  get "config_siemens/:phone/:sip_account/menu"            => "config_siemens#menu"

  #Polycom
  get "config_polycom/:phone/:sip_account/phone_book"      => "config_polycom#phone_book"
  get "config_polycom/:phone/:sip_account/call_history"    => "config_polycom#call_history"
  get "config_polycom/:phone/:sip_account/idle_screen"     => "config_polycom#idle_screen"

  #Yealink
  get "config_yealink/:phone/:sip_account/phone_book"      => "config_yealink#phone_book"
  get "config_yealink/:phone/:sip_account/:phone_book/phone_book"         => "config_yealink#phone_book"

  #Gigaset
  get "config_gigaset/:phone/:sip_account/phone_book"      => "config_gigaset#phone_book"
 
  # Unified path for Snom phones.
  # Enter e.g. "http://192.168.1.105:3000/settings"
  # as the Setting URL (Advanced -> Update).
  match 'snom-:provisioning_key' => 'config_snom#snom_phone',
    :via => [:get],
    :format => 'xml'
  match 'snom-:provisioning_key-:mac_address' => 'config_snom#snom_phone',
    :constraints => { :mac_address => /000413[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match 'settings-:mac_address' => 'config_snom#show',
    :constraints => { :mac_address => /000413[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match 'settings-:mac_address' => 'config_yealink#show',
    :constraints => { :mac_address => /001565[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'text'
  match 'gigaset/:build_variant/:provisioning_id/settings-:mac_address' => 'config_gigaset#show',
    :constraints => { :mac_address => /7C2F80[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match 'gigaset/:provisioning_key/:build_variant/:provisioning_id/settings-:mac_address' => 'config_gigaset#show',
    :constraints => { :mac_address => /7C2F80[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match 'gigaset/:build_variant/:provisioning_id/:file_name' => 'config_gigaset#binary',
    :via => [:get],
    :format => 'bin'
  match 'snom_vision-:provisioning_key' => 'config_snom#snom_vision',
    :via => [:get],
    :format => 'xml'
  match 'snom_vision-:provisioning_key-:mac_address' => 'config_snom#snom_vision',
    :constraints => { :mac_address => /000413[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match "/DeploymentService/LoginService" => 'config_siemens#index',
    :via => [:post],
    :format => 'xml'
  match ':mac_address.cfg' => 'config_polycom#config_files',
    :constraints => { :mac_address => /0004f2[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match ':mac_address.cfg' => 'config_yealink#show',
    :constraints => { :mac_address => /001565[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'text'
  match 'settings-:mac_address.cfg' => 'config_polycom#settings',
    :constraints => { :mac_address => /0004f2[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'
  match ':mac_address-directory' => 'config_polycom#settings_directory',
    :constraints => { :mac_address => /0004f2[0-9A-F]{6}/i },
    :via => [:get],
    :format => 'xml'

  # Pingtel
  match 'getConfig' => 'config_pingtel#show',
    :constraints => { :mac_address => /00d01e[0-9a-f]{6}/i },
    :via => [:get],
    :format => 'text'
    
  # Snom default path.
  # e.g. "/snom360-000413000000.htm"
  # Enter e.g. "http://192.168.1.105:3000"
  # as the Setting URL (Advanced -> Update).
  match 'snom:model-:mac_address' => 'config_snom#show',
    :constraints => { :mac_address => /000413[0-9A-F]{6}/i, :model => /[0-9]{3}/ },
    :via => [:get],
    :format => 'xml'
  
  resources :sessions
  
  get "page/index"
  get "page/help"
  
  root :to => "page#index"
  
  resources :users do
    # Display all phone books that the current user owns:
    resources :phone_books
    resources :user_groups, :only => [ :index, :show ]
    resources :sip_accounts
    resources :phones
    resources :conferences
    resources :fax_accounts
    resources :system_messages, :except => [ :edit, :update, :destroy ]
    resources :parking_stalls
    resources :switchboards do
      get :display
    end
    resources :voicemail_accounts
    resources :generic_files
  end
  
  resources :user_groups do
    # Display all phone books that the group of the current user owns:
    resources :phone_books
    resources :sip_accounts
    resources :fax_accounts
    resources :user_group_memberships
  end
  
  resources :tenants do
    # Display all phone books that the tenant of the current user owns:
    resources :phone_books
    resources :users do
      get "destroy_avatar"
    end
    resources :user_groups
    resources :sip_accounts
    resources :phones
    resources :conferences
    resources :phone_number_ranges
    resources :callthroughs
    if GsParameter.get('CALLTHROUGH_HAS_WHITELISTS') == true
      resources :whitelists
    end
    resources :hunt_groups
    resources :automatic_call_distributors
    resources :parking_stalls
    resources :voicemail_accounts
    resources :fax_accounts
    resources :generic_files
  end

  resources :callthroughs, :only => [] do
    resources :access_authorizations
    resources :phone_numbers
    if GsParameter.get('CALLTHROUGH_HAS_WHITELISTS') == true
      resources :whitelists
    end
  end

  resources :softkeys, :only => [ :sort ] do
    collection { post :sort }
  end

  resources :sip_accounts, :only => [] do
    resources :phones_sip_accounts
    resources :phone_numbers
    resources :softkeys
    resources :call_forwards
    resources :ringtones
    resources :calls
    resources :acd_agents
    resources :call_histories do
      collection do
        delete 'destroy_multiple'
      end
      member do
        put 'call'
      end
    end
    resources :voicemail_accounts
    resources :pager_groups
  end

  resources :phones, :only => [] do
    resources :phone_sip_accounts
    resources :extension_modules do
      member do
        put 'restart'
      end
    end
  end
  
  # Display all phone book entries that the current user can access:
  resources :phone_book_entries, :only => [ :index, :show ] do
    resources :phone_numbers do
      member do
        put 'call'
      end
    end
  end
  
  # Display all phone books that the current user can access:
  resources :phone_books, :only => [ :index, :show ] do
    resources :phone_book_entries
  end
  
  # Search
  post "search" => "phone_book_entries#index", :as => 'search'
  
  # http://0.0.0.0:3000/phone_books/3?name=Wintermeyer
  
  
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products
  
  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end
  
  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end
  
  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end
  
  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  
  # See how all your routes lay out with "rake routes"
  
  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
