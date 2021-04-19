class ErrorsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Exception, with: :exception_notification
  rescue_from ActionController::RoutingError, with: :not_found

  def not_found
    render(status: :not_found)
  end

  def internal_server_error
    exception_notification
    render(status: :internal_server_error)
  end

  private

  def exception_notification
    exception = $!
    unless exception.nil?
      logger.debug "\n\n*************************** ErrorsController.exception_notification: ***************************\n\n"
      logger.debug "Exception object: #{exception.inspect}"
      logger.debug "Exception object message: #{exception.message}"
      logger.debug "\n\n*************************** ErrorsController.exception_notification end ***************************\n\n"

      user = @current_user.nil? ? request.remote_ip : %Q["#{@current_user.name}" <#{@current_user.email}>]
      error_message = "User: #{user} invoked #{exception.class}: #{exception.message}"
      report = ErrorReport.new(exception.class, @event)
      report.add(exception, error_message)
      report.send_report
    end
  end
end
