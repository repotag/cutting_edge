require File.expand_path('../../badge.rb', __FILE__)
require File.expand_path('../helpers.rb', __FILE__)

class BadgeWorker < GenericWorker

  def perform(identifier)
    log_info 'Running Worker!'
    dependencies = get_from_store(identifier)
    status = dependencies ? generate_status(dependencies[:outdated]) : :unknown
    add_to_store("svg-#{identifier}", Badge.build_badge(status, dependencies[:outdated_total]))
    GC.start
  end

  private

  def generate_status(status)
    # status is more specific than Badge.build_badge currently expects, so make it a bit less so
    status == :up_to_date ? status : :out_of_date
  end
end