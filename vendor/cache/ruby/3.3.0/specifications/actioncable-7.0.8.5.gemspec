# -*- encoding: utf-8 -*-
# stub: actioncable 7.0.8.5 ruby lib

Gem::Specification.new do |s|
  s.name = "actioncable".freeze
  s.version = "7.0.8.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.0.8.5/actioncable/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.0.8.5/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.0.8.5/actioncable" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pratik Naik".freeze, "David Heinemeier Hansson".freeze]
  s.date = "2024-10-15"
  s.description = "Structure many real-time application concerns into channels over a single WebSocket connection.".freeze
  s.email = ["pratiknaik@gmail.com".freeze, "david@loudthinking.com".freeze]
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "WebSocket framework for Rails.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<nio4r>.freeze, ["~> 2.0".freeze])
  s.add_runtime_dependency(%q<websocket-driver>.freeze, [">= 0.6.1".freeze])
end
