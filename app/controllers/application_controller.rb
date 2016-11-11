class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead of :exception.
  protect_from_forgery with: :exception
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_auth_token

  # Authorization module
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Enforces access right checks for individuals resources
  #after_filter :verify_authorized, :except => :index

  # Enforces access right checks for collections
  #after_filter :verify_policy_scoped, :except => :index

  before_action :set_paper_trail_whodunnit

  add_flash_types :warning, :success, :info, :error

  def set_event
    if params[:event_id]
      @event = Event.find(params[:event_id])
    elsif params[:id]
      @event = Event.find(params[:id])
    end

    redirect_to events_path, error: 'Event not found.' if @event.nil?
  end

  def set_time_zone
    Time.zone = @event.time_zone if @event && @event.time_zone
  end

  def set_attendance
    @attendance = Membership::ATTENDANCE unless @event.nil?
  end

  private

  def invalid_auth_token
    render text: 'Invalid CSRF token', status: :unauthorized
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore

    respond_to do |format|
      format.html {
        flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
        redirect_to (request.referrer || my_events_path)
      }
      format.json { head 403 }
    end
  end

  # After successful login, redirect to welcome page
  def after_sign_in_path_for(resource)
    flash[:success] = 'Signed in successfully!' unless flash[:notice]
    welcome_path
  end

  def after_sign_out_path_for(resource)
    sign_in_path
  end

end
