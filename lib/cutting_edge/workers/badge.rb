require File.expand_path('../helpers.rb', __FILE__)

module CuttingEdge
  BADGE_TEMPLATE = File.read(File.expand_path('../../templates/badge.svg.erb', __FILE__)) unless defined?(BADGE_TEMPLATE)
  BADGE_OK = File.read(File.expand_path('../../static/ok.svg', __FILE__)) unless defined?(BADGE_OK)
  BADGE_ERROR = File.read(File.expand_path('../../static/error.svg', __FILE__)) unless defined?(BADGE_ERROR)
  BADGE_BASE_WIDTH = 25 unless defined?(BADGE_BASE_WIDTH)
  BADGE_CELL_WIDTH = 25 unless defined?(BADGE_CELL_WIDTH)
  BADGE_LAYOUT = {
    ok: '#4c1',
    outdated_patch: '#dfb317',
    outdated_minor: '#fe7d37',
    outdated_major: '#e05d44',
    unknown: '#9f9f9f'
  } unless defined?(BADGE_LAYOUT) # Order is significant
end

class BadgeWorker < GenericWorker

  def perform(identifier)
    log_info 'Running Worker!'
    dependencies = get_from_store(identifier)
    
    if dependencies && !dependencies.empty?
      result = if dependencies[:outdated] == :up_to_date
        CuttingEdge::BADGE_OK
      else
        dependencies = ::CuttingEdge::BADGE_LAYOUT.keys.map { |k| [k, dependencies[k]] }.to_h.
          delete_if {|type, number| number == 0}
        ERB.new(CuttingEdge::BADGE_TEMPLATE).result_with_hash(
          base_width: CuttingEdge::BADGE_BASE_WIDTH,
          cell_width: CuttingEdge::BADGE_CELL_WIDTH,
          colors: CuttingEdge::BADGE_LAYOUT,
          dependencies: dependencies
        )
      end
    else
      result = CuttingEdge::BADGE_ERROR
    end
    
    add_to_store("svg-#{identifier}", result)
    GC.start
  end
end