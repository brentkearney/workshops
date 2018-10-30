Rails.application.routes.draw do
  root 'welcome#index'

  # Devise (login/logout)
  devise_for :users, path_names: { sign_up: 'register', sign_in: 'sign_in' },
                     controllers: { registrations: 'registrations',
                                    sessions: 'sessions',
                                    confirmations: 'confirmations' }

  devise_scope :user do
    get 'sign_in' => 'devise/sessions#new'
    get 'register' => 'devise/registrations#new'
    delete 'sign_out' => 'devise/sessions#destroy'
    get 'confirmation/sent' => 'confirmations#sent'
    patch 'users/confirmation' => 'confirmations#create'
  end

  # Post-login welcome page
  get 'welcome' => 'welcome#index'

  # Events, schedules, memberships
  get 'events/my_events' => 'events#my_events', as: :my_events
  get 'events/past(/location/:location)' => 'events#past', as: :events_past
  get 'events/future(/location/:location)' => 'events#future', as: :events_future
  get 'events/year/:year(/location/:location)' => 'events#year', as: :events_year
  get 'events/location/:location(/year/:year)' => 'events#location', as: :events_location
  get 'events/kind/:kind' => 'events#kind', as: :events_kind

  resources :events do
    get 'schedule/new/:day' => 'schedule#new', as: :schedule_day
    get 'schedule/new/:day/item' => 'schedule#new_item', as: :schedule_item
    get 'schedule/:id' => 'schedule#edit', as: :schedule_edit
    post 'schedule/create' => 'schedule#create'
    post 'schedule/publish_schedule' => 'schedule#publish_schedule'
    resources :schedule
    resources :memberships
    put 'memberships/invite/:id' => 'memberships#invite',
      as: :memberships_invite
    get 'lectures' => 'lectures#index'
  end

  resources :settings
  post 'settings/delete' => 'settings#delete'

  # Errors
  match "/404", :to => "errors#not_found", via: :all
  match "/500", :to => "errors#internal_server_error", via: :all

  # Invitations & RSVP
  get '/invitations' => 'invitations#index'
  get '/invitations/new' => 'invitations#new'
  post '/invitations/create' => 'invitations#create'
  get '/invitations/send/:membership_id' => 'invitations#send_invite',
      as: :invitations_send

  get '/rsvp' => 'rsvp#index'
  get '/rsvp/:otp' => 'rsvp#index', as: :rsvp_otp, constraints: { otp: /[^\/]+/ }
  match '/rsvp/yes/:otp' => 'rsvp#yes', as: :rsvp_yes, via: [:get, :post]
  match '/rsvp/no/:otp' => 'rsvp#no', as: :rsvp_no, via: [:get, :post]
  match '/rsvp/maybe/:otp' => 'rsvp#maybe', as: :rsvp_maybe, via: [:get, :post]
  match '/rsvp/feedback/:membership_id' => 'rsvp#feedback',
        as: :rsvp_feedback, via: [:get, :post]

  # API
  namespace :api do
    namespace :v1 do
      patch 'lectures' => 'lectures#update'
      put 'lectures' => 'lectures#update'
      post 'events' => 'events#create'
      post 'events/sync' => 'events#sync'
    end
  end

  # Maillists
  post "/maillist" => 'griddler/authentication#incoming'

  # Broken Android icon requests
  get '/android-icon-192x192.png', to: redirect('/icons/android-icon-192x192.png')
  get '/android-icon-144x144.png', to: redirect('/icons/android-icon-144x144.png')
  get '/android-icon-96x96.png', to: redirect('/icons/android-icon-96x96.png')
  get '/android-icon-72x72.png', to: redirect('/icons/android-icon-72x72.png')
  get '/android-icon-48x48.png', to: redirect('/icons/android-icon-48x48.png')
  get '/android-icon-36x36.png', to: redirect('/icons/android-icon-36x36.png')
end
