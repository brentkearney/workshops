class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead of :exception.
  protect_from_forgery with: :exception, unless: :json_request?
  skip_before_action :verify_authenticity_token, if: :json_request?
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_auth_token

  # Authorization module
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Enforces access right checks for individuals resources
  #after_action :verify_authorized, :except => :index

  # Enforces access right checks for collections
  #after_action :verify_policy_scoped, :except => :index

  include ApplicationHelper

  before_action :set_paper_trail_whodunnit

  add_flash_types :warning, :success, :info, :error

  def set_event
    event_id = validate_event
    @event = Event.find(event_id) if event_id
    redirect_to events_path, error: 'Event not found.' if @event.blank?
  end

  def set_time_zone
    Time.zone = @event.time_zone if @event && @event.time_zone
  end

  def set_attendance
    @attendance = Membership::ATTENDANCE unless @event.blank?
  end

  private

  def validate_event
    event = params[:event_id] || params[:id]
    event if event =~ /\A\d+\Z/ || event =~ /#{Setting.Site['code_pattern']}/
  end

  def invalid_auth_token
    Rails.logger.debug "\n\nInvalid auth token invoked!\n\n"
    redirect_to sign_in_path, error: 'Login invalid or expired'
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    respond_to do |format|
      format.html do
        flash[:error] = t "#{policy_name}.#{exception.query}",
                          scope: 'pundit', default: :default

        redirect_to request.referrer and return unless request.referrer.nil?
        redirect_to my_events_path and return
      end
      format.json { head 403 }
    end
  end

  # After successful login, redirect to attempted page or welcome page
  def after_sign_in_path_for(_resource)
    flash[:success] = 'Signed in successfully!' unless flash[:notice]
    stored_location_for(_resource) || welcome_path
  end

  def after_sign_out_path_for(_resource)
    sign_in_path
  end

  def json_request?
    request.format.json?
  end
end
