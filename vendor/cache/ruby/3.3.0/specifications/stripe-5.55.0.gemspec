# -*- encoding: utf-8 -*-
# stub: stripe 5.55.0 ruby lib

Gem::Specification.new do |s|
  s.name = "stripe".freeze
  s.version = "5.55.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/stripe/stripe-ruby/issues", "changelog_uri" => "https://github.com/stripe/stripe-ruby/blob/master/CHANGELOG.md", "documentation_uri" => "https://stripe.com/docs/api?lang=ruby", "github_repo" => "ssh://github.com/stripe/stripe-ruby", "homepage_uri" => "https://stripe.com/docs/api?lang=ruby", "source_code_uri" => "https://github.com/stripe/stripe-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stripe".freeze]
  s.date = "2022-05-05"
  s.description = "Stripe is the easiest way to accept payments online.  See https://stripe.com for details.".freeze
  s.email = "support@stripe.com".freeze
  s.executables = ["stripe-console".freeze]
  s.files = ["bin/stripe-console".freeze]
  s.homepage = "https://stripe.com/docs/api?lang=ruby".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby bindings for the Stripe API".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version
end
