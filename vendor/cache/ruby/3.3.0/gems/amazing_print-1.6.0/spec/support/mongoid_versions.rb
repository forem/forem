# frozen_string_literal: true

module MongoidVersions
  def mongoid_version
    Gem::Version.new(Mongoid::VERSION)
  end

  def mongoid_4_0?
    Gem::Requirement.new('~> 4.0.0').satisfied_by?(mongoid_version)
  end

  def mongoid_5_0?
    Gem::Requirement.new('~> 5.0.0').satisfied_by?(mongoid_version)
  end

  def mongoid_6_0?
    Gem::Requirement.new('~> 6.0.0').satisfied_by?(mongoid_version)
  end
end

RSpec.configure do |config|
  config.include(MongoidVersions)
  config.extend(MongoidVersions)
end
