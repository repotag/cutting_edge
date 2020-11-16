require 'sinatra/logger'
require 'sucker_punch'

module WorkerHelpers

  def log_info(message)
    logger.info(message) if ::CuttingEdge::App.enable_logging
  end

  def add_to_store(identifier, dependencies)
    ::CuttingEdge::App.store[identifier] = dependencies
  end

  def get_from_store(identifier)
    ::CuttingEdge::App.store[identifier]
  end
  
  def delete_from_store(identifier)
    ::CuttingEdge::App.store.delete(identifier)
  end
  
  def badge_worker(identifier)
    BadgeWorker.perform_async(identifier)
  end
  
  def mail_worker(identifier, to_address)
    MailWorker.perform_async(identifier, to_address)
  end
  
end

class GenericWorker
  include ::SuckerPunch::Job
  include ::WorkerHelpers
  include ::SemanticLogger::Loggable
end