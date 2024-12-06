# -*- encoding: utf-8 -*-
# stub: ferrum 0.14 ruby lib

Gem::Specification.new do |s|
  s.name = "ferrum".freeze
  s.version = "0.14".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubycdp/ferrum/issues", "changelog_uri" => "https://github.com/rubycdp/ferrum/blob/main/CHANGELOG.md", "documentation_uri" => "https://github.com/rubycdp/ferrum/blob/main/README.md", "homepage_uri" => "https://ferrum.rubycdp.com/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rubycdp/ferrum" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dmitry Vorotilin".freeze]
  s.date = "2023-09-14"
  s.description = "Ferrum allows you to control headless Chrome browser".freeze
  s.email = ["d.vorotilin@gmail.com".freeze]
  s.homepage = "https://github.com/rubycdp/ferrum".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby headless Chrome driver".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.5".freeze])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<webrick>.freeze, ["~> 1.7".freeze])
  s.add_runtime_dependency(%q<websocket-driver>.freeze, [">= 0.6".freeze, "< 0.8".freeze])
end
