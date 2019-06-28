# config/initializers/warden_auth.rb
Warden::JWTAuth.configure do |config|
  config.secret = ENV['DEVISE_JWT_SECRET_KEY']
  config.dispatch_requests = [
                               ['POST', %r{^/users/sign_in$}]
                             ]
end
