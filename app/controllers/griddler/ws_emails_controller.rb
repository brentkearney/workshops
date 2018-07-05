class Griddler::WsEmailsController < Griddler::EmailsController
  skip_before_filter :verify_authenticity_token
  protect_from_forgery with: :null_session
  before_filter :parse_request, :authenticate_user_from_token!
  respond_to :json

  private
  def authenticate_user_from_token!
    @authenticated = false
    unauthorized && return if @auth_token.blank?

    local_auth = GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')
    unavailable && return if local_auth.blank?

    if Devise.secure_compare(local_auth, @auth_token)
      @authenticated = true
    else
      unauthorized
    end
  end

  def parse_request
    @json = JSON.parse(request.body.read)
    @auth_token = request.headers['HTTP_X_MESSAGESYSTEMS_WEBHOOK_TOKEN']
  end

  def unauthorized
    render nothing: true, status: :unauthorized
  end

  def unavailable
    render nothing: true, status: :service_unavailable
  end

  def is_ok
    render nothing: true, status: :ok
  end
end
