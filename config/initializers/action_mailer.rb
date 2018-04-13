# Catch SparkPost errors and send them to mailer.log, notify sysadmin_email
ActionMailer::DeliveryJob.rescue_from(SparkPostRails::DeliveryException) do |exception|
  Rails.logger.info "\n\n" + '*' * 100 + "\n\n"
  Rails.logger.info " SparkPost Error: #{exception.info}"
  Rails.logger.info "\n\n" + '*' * 100 + "\n\n"
  StaffMailer.notify_sysadmin(nil, exception).deliver_now
end
