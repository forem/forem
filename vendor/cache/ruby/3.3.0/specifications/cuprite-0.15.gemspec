# -*- encoding: utf-8 -*-
# stub: cuprite 0.15 ruby lib

Gem::Specification.new do |s|
  s.name = "cuprite".freeze
  s.version = "0.15".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubycdp/cuprite/issues", "documentation_uri" => "https://github.com/rubycdp/cuprite/blob/main/README.md", "homepage_uri" => "https://cuprite.rubycdp.com/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rubycdp/cuprite" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dmitry Vorotilin".freeze]
  s.date = "2023-11-04"
  s.description = "Cuprite is a driver for Capybara that allows you to run your tests on a headless Chrome browser".freeze
  s.email = ["d.vorotilin@gmail.com".freeze]
  s.homepage = "https://github.com/rubycdp/cuprite".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Headless Chrome driver for Capybara".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<capybara>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<ferrum>.freeze, ["~> 0.14.0".freeze])
end
