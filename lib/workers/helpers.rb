require 'sinatra/logger'
require 'sucker_punch'

module WorkerHelpers

  def log_info(message)
    logger.info(message) if defined?(::CuttingEdge) && ::CuttingEdge.enable_logging
  end

  def add_to_store(identifier, dependencies)
    ::CuttingEdge.store[identifier] = dependencies
  end

  def get_from_store(identifier)
    ::CuttingEdge.store[identifier]
  end

end

class GenericWorker
  include ::SuckerPunch::Job
  include ::WorkerHelpers
  include ::SemanticLogger::Loggable
end