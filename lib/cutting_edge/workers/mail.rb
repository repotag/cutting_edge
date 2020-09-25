require File.expand_path('../helpers.rb', __FILE__)
require 'erb'
require 'mail'

module CuttingEdge
  MAIL_TEMPLATE = File.read(File.expand_path('../../templates/mail.html.erb', __FILE__)) unless defined?(MAIL_TEMPLATE)
end

class MailWorker < GenericWorker
  
  def perform(identifier, to_addr)
    log_info('Running Worker!')
    dependencies = get_from_store(identifier)
    unless to_addr && dependencies
      log_info("Failed to execute email job for #{identifier}: #{dependencies ? dependencies : 'No dependencies found.'} #{'No e-mail address set.' if to_addr.nil?}")
      return nil
    end

    Mail.deliver do
      from     CuttingEdge::MAIL_FROM
      to       to_addr
      subject  "Dependency Status Changed For #{identifier}"
      
      text_part do
        body "Dependency Status Update For #{identifier} By CuttingEdge"
      end
      
      html_part do
        content_type 'text/html; charset=UTF-8'
        body  ERB.new(CuttingEdge::MAIL_TEMPLATE).result_with_hash(
          project: identifier,
          url: CuttingEdge::SERVER_URL,
          dependencies: dependencies
        )
      end
    end
  end
end