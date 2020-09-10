require File.expand_path('../../badge.rb', __FILE__)
require File.expand_path('../helpers.rb', __FILE__)

module CuttingEdge
  BADGE_TEMPLATE = File.read(File.expand_path('../../templates/badge.svg.erb', __FILE__)) unless defined?(BADGE_TEMPLATE)
  BADGE_BASE_WIDTH = 35 unless defined?(BADGE_BASE_WIDTH)
  BADGE_CELL_WIDTH = 25 unless defined?(BADGE_CELL_WIDTH)
  BADGE_COLORS = {outdated_major: 'red', outdated_minor: 'orange', outdated_patch: 'yellow', ok: '#4c1', unknown: '#555'} unless defined?(BADGE_COLORS)
end

class BadgeWorker < GenericWorker
  STATUS_TYPES = [:ok, :outdated_patch, :outdated_minor, :outdated_major, :unknown]  # Order is significant

  def perform(identifier)
    log_info 'Running Worker!'
    dependencies = get_from_store(identifier) # What if this fails?
    dependencies = STATUS_TYPES.map { |k| [k, dependencies[k]] }.to_h.
      delete_if {|type, number| number == 0}

    add_to_store("svg-#{identifier}", ERB.new(CuttingEdge::BADGE_TEMPLATE).result_with_hash(
      base_width: ::CuttingEdge::BADGE_BASE_WIDTH,
      cell_width: ::CuttingEdge::BADGE_CELL_WIDTH,
      colors: ::CuttingEdge::BADGE_COLORS,
      dependencies: dependencies
    ))
    GC.start
  end
end