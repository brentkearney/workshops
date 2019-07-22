# config/initializers/warden_auth.rb
Warden::JWTAuth.configure do |config|
  config.secret = ENV['DEVISE_JWT_SECRET_KEY']
  config.dispatch_requests = [
                               ['POST', %r{^/api/login$}],
                               ['POST', %r{^/api/login\.json$}]
                             ]
  config.revocation_requests = [
                                 ['DELETE', %r{^/logout$}],
                                 ['DELETE', %r{^/logout\.json$}]
                               ]
   # TODO: authorize scope :api_user for staff users only
   # from log: Attempting to authenticate with {:scope=>:api_user, :recall=>"api/sessions#new"}...

end
