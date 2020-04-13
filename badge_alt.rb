require 'victor'

svg = Victor::SVG.new width: 160, height: 32, rx: 5, title: 'foo', template: :html

badge_style = {
  stroke: '#d3d3d3',
  stroke_width: 4
}

def style(color)
  {
    stroke: color,
    stroke_width: 3
  }
end

COLORS = {outdated_major: 'red', outdated_minor: 'orange', outdated_patch: 'yellow', ok: '#32CD32', unknown: 'black'}
X_AXIS = {outdated_major: 20, outdated_minor: 50, outdated_patch: 80, ok: 110, unknown: 140}

# Dummy data
t = {outdated_major: 16, outdated_minor: 4, outdated_patch: 235, ok: 90, unknown: 4}

svg.build do
  rect x: 0, y: 0, width: 160, height: 32, fill: '#5d5d5d', rx: 10, style: badge_style

  t.each do |key, value|

    g font_size: 10, font_family: 'arial', fill: 'white' do
      circle cx: X_AXIS[key], cy: 16, r: 12, style: style(COLORS[key]), fill: '#5d5d5d'
      text "#{value}", x: X_AXIS[key], y: 19, text_anchor: "middle"
    end

  end

end

puts svg.render
svg.save 'test'