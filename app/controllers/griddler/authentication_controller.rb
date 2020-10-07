class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_action :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  before_action :authenticate
  respond_to :json

  # Override to add authentication (before_action) & very basic validation
  # https://github.com/thoughtbot/griddler/blob/master/app/controllers/griddler/emails_controller.rb
  def incoming
    create and return if valid_incoming_format
    not_acceptable
  end

  def bounces
    process_bounce and return if valid_bounce_format
    not_acceptable
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

  def not_acceptable
    head :not_acceptable and return
  end

  def is_ok
    head :ok
  end

  protected

  def valid_incoming_format
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
    return if params['signature'].nil?
    return params['signature'] if params['signature'].class == String
    params['signature']['signature']
  end

  def parse_params
    timestamp = token = nil
    if params['timestamp'] && params['signature'].class == String
      timestamp = params['timestamp']
      token = params['token']
    elsif params['signature'] && params['signature']['timestamp']
      timestamp = params['signature']['timestamp']
      token = params['signature']['token']
    end
    return [timestamp, token]
  end

  def posted_token
    timestamp, token = parse_params
    return '' unless timestamp && token
    timestamp + token
  end

  def encoded_token
    if ENV['MAILGUN_API_KEY'].nil?
      Rails.logger.debug "\n\nGriddler::AuthenticationController: no Mailgun API key set!\n\n"
      msg = { problem: 'No Mailgun API key set!' }
      StaffMailer.notify_sysadmin(nil, msg).deliver_now
      unauthorized and return
    end
    digest = OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, ENV['MAILGUN_API_KEY'], posted_token)
  end
end
