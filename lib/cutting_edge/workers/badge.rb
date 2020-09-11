require File.expand_path('../helpers.rb', __FILE__)

module CuttingEdge
  BADGE_TEMPLATE = File.read(File.expand_path('../../templates/badge.svg.erb', __FILE__)) unless defined?(BADGE_TEMPLATE)
  BADGE_BASE_WIDTH = 35 unless defined?(BADGE_BASE_WIDTH)
  BADGE_CELL_WIDTH = 25 unless defined?(BADGE_CELL_WIDTH)
  BADGE_LAYOUT = {
    ok: '#4c1',
    outdated_patch: 'yellow',
    outdated_minor: 'orange',
    outdated_major: 'red',
    unknown: '#555'
  } unless defined?(BADGE_LAYOUT) # Order is significant
end

class BadgeWorker < GenericWorker

  def perform(identifier)
    log_info 'Running Worker!'
    dependencies = get_from_store(identifier) # What if this fails?
    dependencies = ::CuttingEdge::BADGE_LAYOUT.keys.map { |k| [k, dependencies[k]] }.to_h.
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