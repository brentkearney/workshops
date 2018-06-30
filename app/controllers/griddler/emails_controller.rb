class Griddler::EmailsController < ActionController::Base
  skip_before_filter :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_filter :parse_request, :authenticate_user_from_token!
  respond_to :json

  def authenticate_user_from_token!
    @authenticated = false
    unauthorized && return if @json['auth_token'].blank?

    local_auth = Setting.Site['SPARKPOST_AUTH_TOKEN']
    unavailable && return if local_auth.blank?

    if Devise.secure_compare(local_auth, @json['auth_token'])
      @authenticated = true
    else
      unauthorized
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
  end

  def unauthorized
    render nothing: true, status: :unauthorized
  end

  def unavailable
    render nothing: true, status: :service_unavailable
  end
end
