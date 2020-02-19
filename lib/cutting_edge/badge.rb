require 'victor'

class Badge
  BADGE_OPTIONS = {
    up_to_date: {
      bg_color: '#32CD32',
      text: 'up-to-date',
      width: 180
    },
    out_of_date: {
      bg_color: '#ff0000',
      text: 'out-of-date',
      width: 190
    },
    unknown: {
      bg_color: '#666',
      text: 'unknown',
      width: 170
    }
  }

  def self.build_badge(status, num=nil)
    if ! [:up_to_date, :out_of_date, :unknown].include?(status)
      status = :unknown
    end
    number = Integer(num) rescue nil if num

    svg = Victor::SVG.new width: BADGE_OPTIONS[status][:width], height: 32, template: :html

    style = {
      stroke: '#d3d3d3',
      stroke_width: 4
    }

    svg.build do
      rect x: 0, y: 0, width: BADGE_OPTIONS[status][:width], height: 32, fill: BADGE_OPTIONS[status][:bg_color], style: style

      g font_size: 14, font_family: 'arial', fill: 'white' do
        text "#{number} Dependencies #{BADGE_OPTIONS[status][:text]}", x: 10, y: 20
      end
    end
    return svg.render
  end

end

