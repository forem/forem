# -*- encoding: utf-8 -*-
# stub: actionmailbox 7.0.8.5 ruby lib

Gem::Specification.new do |s|
  s.name = "actionmailbox".freeze
  s.version = "7.0.8.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.0.8.5/actionmailbox/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.0.8.5/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.0.8.5/actionmailbox" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze, "George Claghorn".freeze]
  s.date = "2024-10-15"
  s.description = "Receive and process incoming emails in Rails applications.".freeze
  s.email = ["david@loudthinking.com".freeze, "george@basecamp.com".freeze]
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Inbound email handling framework.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<activestorage>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<activejob>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, ["= 7.0.8.5".freeze])
  s.add_runtime_dependency(%q<mail>.freeze, [">= 2.7.1".freeze])
  s.add_runtime_dependency(%q<net-imap>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<net-pop>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<net-smtp>.freeze, [">= 0".freeze])
end
