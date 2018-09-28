class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_filter :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  before_action :authenticate
  respond_to :json

  def incoming
    create and return if valid_email_format
    bad_request
  end

  private

  def unauthorized
    Rails.logger.debug "\n\nGriddler::AuthenticationController: authorization failed [#{posted_token}].\n\n"
    render nothing: true, status: :unauthorized and return
  end

  def bad_request
    render nothing: true, status: :bad_request and return
  end

  def is_ok
    render nothing: true, status: :ok
  end

  protected

  def valid_email_format
    if params.key?('_json') && params['_json'].kind_of?(Array)
      if params['_json'][0].key?('msys')
        if params['_json'][0]['msys'].key?('relay_message')
          return true
        else
          return false
        end
      else
        return false
      end
    end
    false
  end

  def authenticate
    verify_sparkpost_token || unauthorized
  end

  def verify_sparkpost_token
    posted_token == valid_token
  end

  def posted_token
    request.headers["X-MessageSystems-Webhook-Token"]
  end

  def valid_token
    GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')
  end
end
