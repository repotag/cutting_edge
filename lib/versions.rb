require 'rubygems'

module VersionRequirementComparator

  def version_requirement_diff(requirement, latest_version)
    segments = latest_version.canonical_segments
    constraints = []

    requirement.requirements.each do |comparator, version|
      if comparator == '~>'
        constraints = constraints + translate_tilde(version)
      else
        constraints << Gem::Requirement.new("#{comparator} #{version.to_s}")
      end
    end

    segments.each_with_index do |_v, position|
      check_version = Gem::Version.new(segments[0..position].join('.'))
      constraints.each do |constraint|
        # Since we know `latest_version` is higher than the requirement, we can and must ignore cases where the constraint fails because `check_version` is lower
        # Such cases are caused by the fact that we are generating `check_version` by chopping off the version decimals after `position`
        # For example: `latest_version` is 3.5. On the first pass of this loop, we will thus be checking version 3.0.
        # This would fail a ~> 3.2 requirement on the first pass, falsely yielding an `:outdated_major`.
        unless higher_than_operator?(constraint.requirements.first.first) || constraint.satisfied_by?(check_version)
          return version_difference_type(position)
        end
      end
    end
    return :unknown # This can occur if latest_version is actually lower than the requirement (e.g., when a newer version of a gem has been yanked)
  end

  private

  # Translate ~> contraints to two individual constraints: >= lower_bound && < upper_bound
  def translate_tilde(version)
    segments = version.canonical_segments.dup
    segments.pop while segments.any? { |s| String === s } # Ignore alpha, pre, etc.
    (1..(3 - segments.length)).each do
      segments << 0
    end
    lower_bound = segments[0..-2].join('.')
    return Gem::Requirement.new(">= #{lower_bound}"), Gem::Requirement.new("< #{version.bump.to_s}")
  end

  def higher_than_operator?(comparator)
    ['>', '>='].include?(comparator)
  end

  def version_difference_type(position)
    case position
    when 0
      :outdated_major
    when 1
      :outdated_minor
    else
      :outdated_bump
    end
  end
end