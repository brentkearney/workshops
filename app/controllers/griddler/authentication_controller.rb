class Griddler::AuthenticationController < Griddler::EmailsController
  skip_before_filter :verify_authenticity_token, raise: false
  protect_from_forgery with: :null_session
  respond_to :json
  http_basic_authenticate_with name: 'sparkpost', password: GetSetting.site_setting('SPARKPOST_AUTH_TOKEN')

  def incoming
    if params['_json'][0]['msys'].empty? || params['_json'][0]['msys']['message_event'] != nil
      msg = "Received POST on Workshops /maillist interface:\n\n #{params.inspect}"
      StaffMailer.incoming_mail_event(msg).deliver_now
      is_ok
    else
      create && return
    end
  end

  private

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
