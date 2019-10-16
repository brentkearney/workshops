class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_action :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  before_action :authenticate
  respond_to :json

  def incoming
    create and return if valid_email_format
    bad_request
  end

  def bounces
    process_bounce and return if valid_bounce_format
    bad_request
  end

  private

  def process_bounce
    EmailBounce.new(params).process
    is_ok
  end

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
    params.key?("X-Mailgun-Incoming")
  end

  def valid_bounce_format
    params.key?('event-data') && params['event-data'].key?('severity') &&
      params['event-data']['severity'] == 'permanent'
  end

  def authenticate
    verify_token || unauthorized
  end

  def verify_token
    encoded_token == posted_signature
  end

  def posted_signature
    params['signature']['signature'] || params['signature'] || 'invalid'
  end

  def posted_token
    timestamp = params['timestamp'] || params['signature']['timestamp']
    token = params['token'] || params['signature']['token']
    return '' unless timestamp && token
    timestamp + token
  end

  def encoded_token
    digest = OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_API_KEY'], posted_token)
  end
end
