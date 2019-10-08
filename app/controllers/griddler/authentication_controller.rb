class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_action :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  before_action :authenticate
  respond_to :json

  def incoming
    create and return if valid_email_format
    bad_request
  end

  private

  def unauthorized
    Rails.logger.debug "\n\nGriddler::AuthenticationController: authentication failed.\n\n"
    head :unauthorized and return
  end

  def bad_request
    head :bad_request and return
  end

  def is_ok
    head :ok
  end

  protected

  def valid_email_format
    return true
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
    verify_token || unauthorized
  end

  def verify_token
    encoded_token == posted_signature
  end

  def posted_signature
    params['signature']
  end

  def posted_token
    return '' unless params['timestamp'] && params['token']
    params['timestamp'] + params['token']
  end

  def encoded_token
    digest = OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_API_KEY'], posted_token)
  end
end
