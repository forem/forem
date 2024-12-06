# -*- encoding: utf-8 -*-
# stub: with_model 2.1.7 ruby lib

Gem::Specification.new do |s|
  s.name = "with_model".freeze
  s.version = "2.1.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Case Commons, LLC".freeze, "Grant Hutchins".freeze, "Andrew Marshall".freeze]
  s.date = "2023-09-15"
  s.description = "Dynamically build a model within an RSpec context".freeze
  s.email = ["casecommons-dev@googlegroups.com".freeze, "gems@nertzy.com".freeze, "andrew@johnandrewmarshall.com".freeze]
  s.homepage = "https://github.com/Casecommons/with_model".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Dynamically build a model within an RSpec context".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.0".freeze])
end
