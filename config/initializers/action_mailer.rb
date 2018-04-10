# Catch SparkPost errors and send them to mailer.log, notify sysadmin_email
ActionMailer::DeliveryJob.rescue_from(SparkPostRails::DeliveryException) do |exception|
  ActionMailer.logger.info "\n\n" + '*' * 100 + "\n\n"
  ActionMailer.logger.info " SparkPost Error: #{exception.info}"
  ActionMailer.logger.info "\n\n" + '*' * 100 + "\n\n"
  StaffMailer.notify_sysadmin(nil, exception).deliver_now
end
