class ErrorsController < ApplicationController
  def not_found
    render(:status => 404)
  end

  def internal_server_error
    exception_notification
    render(:status => 500)
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
