require 'sinatra/logger'
require 'sucker_punch'

module WorkerHelpers

  def log_info(message)
    logger.info(message) if ::RubyDeps.enable_logging
  end

  def add_to_store(identifier, dependencies)
    ::RubyDeps.store[identifier] = dependencies
  end

  def get_from_store(identifier)
    ::RubyDeps.store[identifier]
  end

end

class GenericWorker
  include ::SuckerPunch::Job
  include ::WorkerHelpers
  include ::SemanticLogger::Loggable
end