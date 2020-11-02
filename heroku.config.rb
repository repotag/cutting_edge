# Default settings required for Heroku deployment

module CuttingEdge
  SERVER_HOST = "#{ENV['HEROKU_APP_NAME']}.herokuapp.com" # At what domain is this CuttingEdge instance running?
  SERVER_URL = "https://#{SERVER_HOST}"
  MAIL_TO = ENV['CUTTING_EDGE_MAIL_TO'] if ENV['CUTTING_EDGE_MAIL_TO']
  
  # Your additional configuration goes here.
  # If you are going to host the repository containing this file publically (e.g. on GitHub), please read:
  # https://github.com/repotag/cutting_edge/blob/master/README.md#Defining-repositories-in-configrb
end

# Needed to write to Heroku logs.
::SemanticLogger.add_appender(io: $stderr)

# Configure mail server settings
require 'mail'
Mail.defaults do
  delivery_method :smtp, address: ENV['MAILGUN_SMTP_SERVER'], port: ENV['MAILGUN_SMTP_PORT'], user_name: ENV['MAILGUN_SMTP_LOGIN'], password: ENV['MAILGUN_SMTP_PASSWORD'], domain: CuttingEdge::SERVER_HOST
end
