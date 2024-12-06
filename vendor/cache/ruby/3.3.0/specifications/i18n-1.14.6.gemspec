# -*- encoding: utf-8 -*-
# stub: i18n 1.14.6 ruby lib

Gem::Specification.new do |s|
  s.name = "i18n".freeze
  s.version = "1.14.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-i18n/i18n/issues", "changelog_uri" => "https://github.com/ruby-i18n/i18n/releases", "documentation_uri" => "https://guides.rubyonrails.org/i18n.html", "source_code_uri" => "https://github.com/ruby-i18n/i18n" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sven Fuchs".freeze, "Joshua Harvey".freeze, "Matt Aimonetti".freeze, "Stephan Soller".freeze, "Saimon Moore".freeze, "Ryan Bigg".freeze]
  s.date = "2024-09-15"
  s.description = "New wave Internationalization support for Ruby.".freeze
  s.email = "rails-i18n@googlegroups.com".freeze
  s.homepage = "https://github.com/ruby-i18n/i18n".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "PSA: I18n will be dropping support for Ruby < 3.2 in the next major release (April 2025), due to Ruby's end of life for 3.1 and below (https://endoflife.date/ruby). Please upgrade to Ruby 3.2 or newer by April 2025 to continue using future versions of this gem.".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "New wave Internationalization support for Ruby".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
end
