Rails.application.routes.draw do
  root 'welcome#index'

  # Devise (login/logout)
  devise_for :users, path_names: { sign_up: 'register', sign_in: 'sign_in' },
             :controllers => { :registrations => 'registrations',
                               :sessions => 'sessions',
                               :confirmations => 'confirmations'}

  devise_scope :user do
    get 'sign_in' => 'devise/sessions#new'
    get 'register' => 'devise/registrations#new'
    delete 'sign_out' => 'devise/sessions#destroy'
    get 'confirmation/sent' => 'confirmations#sent'
  end

  # Post-login welcome page
  get 'welcome' => 'welcome#index'

  # Events, schedules, memberships
  get 'events/my_events' => 'events#my_events', as: :my_events
  get 'events/past' => 'events#past', as: :events_past
  get 'events/future' => 'events#future', as: :events_future
  get 'events/year/:year' => 'events#year', as: :events_year
  get 'events/location/:location' => 'events#location', as: :events_location
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

  get '/rsvp' => 'rsvp#index'
  get '/rsvp/:otp' => 'rsvp#index', as: :rsvp_otp
  get '/rsvp/yes/:otp' => 'rsvp#yes', as: :rsvp_yes
  match '/rsvp/no/:otp' => 'rsvp#no', as: :rsvp_no, via: [:get, :post]
  match '/rsvp/maybe/:otp' => 'rsvp#maybe', as: :rsvp_maybe, via: [:get, :post]
  match '/rsvp/feedback/:membership_id' => 'rsvp#feedback',
    as: :rsvp_feedback, via: [:get, :post]

  # API
  namespace :api do
    namespace :v1 do
      patch 'lectures' => 'lectures#update'
      put 'lectures' => 'lectures#update'
    end
  end
end
