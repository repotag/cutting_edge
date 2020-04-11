require File.expand_path('../helpers.rb', __FILE__)
require 'erb'
require 'mail'

module CuttingEdge
  MAIL_TEMPLATE = File.read(File.expand_path('../../templates/mail.html.erb', __FILE__))
end

class MailWorker < GenericWorker
  
  def perform(identifier, to_addr)
    log_info('Running Worker!')
    dependencies = get_from_store(identifier)

    mail = Mail.new do
      from     CuttingEdge::App.settings[:email_from] || 'cutting_edge@localhost'
      to       to_addr
      subject  "Dependency Status Changed For #{identifier}"
      
      text_part do
        body "Dependency Status Update For #{identifier} By CuttingEdge"
      end
      
      html_part do
        content_type 'text/html; charset=UTF-8'
        body  ERB.new(CuttingEdge::MAIL_TEMPLATE).result_with_hash(
          project_name: identifier,
          url: 'http://127.0.0.1',
          dependencies: dependencies
        )
      end
    end
    
    puts mail.to_s
    mail.deliver!
  end
end