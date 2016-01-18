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
  get 'organizers' => 'welcome#organizers', as: :welcome_organizers
  get 'admin' => 'welcome#admin', as: :welcome_admin
  get 'staff' => 'welcome#staff', as: :welcome_staff
  get 'participants' => 'welcome#participants', as: :welcome_member

  # Events, schedules, memberships
  get 'events/kind/:kind' => 'events#index', as: :event_kind
  get 'events/scope/:scope' => 'events#index', as: :event_scope
  get 'events/all' => 'events#all', as: :events_all
  resources :events do
    get 'schedule/new/:day' => 'schedule#new', as: :schedule_day
    get 'schedule/new/:day/item' => 'schedule#new_item', as: :schedule_item
    get 'schedule/:id' => 'schedule#edit', as: :schedule_edit
    post 'schedule/create' => 'schedule#create'
    get 'schedule/send/videos' => 'schedule#send_video_filenames'
    post 'schedule/publish_schedule' => 'schedule#publish_schedule'
    resources :schedule
    #resources :lectures
    resources :memberships
    put 'memberships/invite/:id' => 'memberships#invite', as: :memberships_invite
  end

  # API
  namespace :api do
    namespace :v1 do
      # resources :lectures, only: [:update]
      patch 'lectures' => 'lectures#update'
      put 'lectures' => 'lectures#update'
    end
  end
end
