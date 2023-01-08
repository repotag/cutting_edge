# Example settings for deployment on render.com

module CuttingEdge
  SERVER_HOST = "#{ENV['RENDER_EXTERNAL_HOSTNAME']}" # At what domain is this CuttingEdge instance running?
  SERVER_URL = "https://#{SERVER_HOST}"

  if ENV['REDIS_HOST'] # If redis is defined in your render.yaml, this will automatically use it.
    require 'moneta'
    require 'openssl'
    redis_url = "redis://#{ENV['REDIS_HOST']}"
    redis_url = "#{redis_url}:#{ENV['REDIS_PORT']}" if ENV['REDIS_PORT']
    STORE = ::Moneta.new(:Redis,
      url: redis_url,
      ssl_params: {
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }
    )
  end

  # Your additional configuration goes here.
  # See for options: https://github.com/repotag/cutting_edge/blob/main/config.rb
  # If you are going to host the repository containing this file publically (e.g. on GitHub), please read:
  # https://github.com/repotag/cutting_edge/blob/master/README.md#Defining-repositories-in-configrb
end

# Needed to write to Render logs.
::SemanticLogger.add_appender(io: $stderr)

# Configure mail server settings if desired:

# require 'mail'
# Mail.defaults do
#   delivery_method :smtp, address: '', port: 587, user_name: '', password: '', enable_ssl: true, domain: 'my-cuttingedge.render.com'
# end
