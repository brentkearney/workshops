class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_filter :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  before_action :authenticate
  respond_to :json

  def incoming
    Rails.logger.debug "\n\nGriddler::AuthenticationController: authentication checks out!\n\n"
    create && return
  end

  private

  def unauthorized
    render nothing: true, status: :unauthorized and return
  end

  def unavailable
    render nothing: true, status: :service_unavailable and return
  end

  def is_ok
    render nothing: true, status: :ok
  end

  protected

  def authenticate
    verify_sparkpost_token || unauthorized
  end

  def verify_sparkpost_token
    request.headers["X-MessageSystems-Webhook-Token"] == valid_token?
  end

  def valid_token?
    GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')
  end
end
