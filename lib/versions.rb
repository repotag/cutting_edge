require 'rubygems'

module VersionRequirementComparator

  # Operators that require the checked version to be higher than the required version
  HIGHER_THAN = ['>', '>=']

  def version_requirement_diff(requirement, latest_version)
    segments = latest_version.canonical_segments

    # Since we know `latest_version` is higher than the requirement, we can and must ignore cases where the constraint fails because `check_version` is lower
    # Such cases would be caused by the fact that we are generating `check_version` below by chopping off the version decimals after `position`
    # For example: `latest_version` is 3.5. On the first pass of this loop, we will thus be checking version 3.0.
    # This would fail a ~> 3.2 requirement on the first pass, falsely yielding an `:outdated_major`.
    # Therefore, filter out the HIGHER_THAN operators
    constraints = requirement.requirements.map do |comparator, version|
      if comparator == '~>'
        Gem::Requirement.new("< #{version.bump.to_s}") # Use only the upper bound requirement of a ~> comparison
      elsif !HIGHER_THAN.include?(comparator)
        Gem::Requirement.new("#{comparator} #{version.to_s}")
      end
    end.compact

    segments.each_with_index do |_v, position|
      check_version = Gem::Version.new(segments[0..position].join('.'))
      constraints.each do |constraint|
        unless constraint.satisfied_by?(check_version)
          return version_difference_type(position)
        end
      end
    end
    return :unknown # This can occur if latest_version is actually lower than the requirement (e.g., when a newer version of a gem has been yanked)
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