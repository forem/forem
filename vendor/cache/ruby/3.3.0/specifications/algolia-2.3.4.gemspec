# -*- encoding: utf-8 -*-
# stub: algolia 2.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "algolia".freeze
  s.version = "2.3.4".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/algolia/algoliasearch-client-ruby/issues", "documentation_uri" => "https://www.algolia.com/doc/api-client/getting-started/install/ruby", "source_code_uri" => "https://github.com/algolia/algoliasearch-client-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Algolia".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-11-27"
  s.description = "A simple Ruby client for the algolia.com REST API".freeze
  s.email = ["support@algolia.com".freeze]
  s.homepage = "https://github.com/algolia/algoliasearch-client-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A simple Ruby client for the algolia.com REST API".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["<= 0.82.0".freeze])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.15".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<faraday-net_http_persistent>.freeze, [">= 0.15".freeze, "< 3".freeze])
  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<net-http-persistent>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<httpclient>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<m>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-hooks>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<minitest-proveit>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
end
