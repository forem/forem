# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), 'lib', 'algoliasearch', 'version')

require 'date'

Gem::Specification.new do |s|
  s.name = "algoliasearch-rails"
  s.version = AlgoliaSearch::VERSION

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Algolia"]
  s.date = Date.today
  s.description = "AlgoliaSearch integration to your favorite ORM"
  s.email = "contact@algolia.com"
  s.extra_rdoc_files = [
    "CHANGELOG.MD",
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".document",
    ".rspec",
    "CHANGELOG.MD",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "algoliasearch-rails.gemspec",
    "lib/algoliasearch-rails.rb",
    "lib/algoliasearch/algolia_job.rb",
    "lib/algoliasearch/configuration.rb",
    "lib/algoliasearch/pagination.rb",
    "lib/algoliasearch/pagination/kaminari.rb",
    "lib/algoliasearch/pagination/pagy.rb",
    "lib/algoliasearch/pagination/will_paginate.rb",
    "lib/algoliasearch/railtie.rb",
    "lib/algoliasearch/tasks/algoliasearch.rake",
    "lib/algoliasearch/utilities.rb",
    "lib/algoliasearch/version.rb",
    "spec/spec_helper.rb",
    "spec/utilities_spec.rb",
    "vendor/assets/javascripts/algolia/algoliasearch.angular.js",
    "vendor/assets/javascripts/algolia/algoliasearch.angular.min.js",
    "vendor/assets/javascripts/algolia/algoliasearch.jquery.js",
    "vendor/assets/javascripts/algolia/algoliasearch.jquery.min.js",
    "vendor/assets/javascripts/algolia/algoliasearch.js",
    "vendor/assets/javascripts/algolia/algoliasearch.min.js",
    "vendor/assets/javascripts/algolia/bloodhound.js",
    "vendor/assets/javascripts/algolia/bloodhound.min.js",
    "vendor/assets/javascripts/algolia/typeahead.bundle.js",
    "vendor/assets/javascripts/algolia/typeahead.bundle.min.js",
    "vendor/assets/javascripts/algolia/typeahead.jquery.js",
    "vendor/assets/javascripts/algolia/typeahead.jquery.min.js",
    "vendor/assets/javascripts/algolia/v2",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.angular.js",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.angular.min.js",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.jquery.js",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.jquery.min.js",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.js",
    "vendor/assets/javascripts/algolia/v2/algoliasearch.min.js",
    "vendor/assets/javascripts/algolia/v3",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.angular.js",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.angular.min.js",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.jquery.js",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.jquery.min.js",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.js",
    "vendor/assets/javascripts/algolia/v3/algoliasearch.min.js"
  ]
  s.homepage = "http://github.com/algolia/algoliasearch-rails"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "AlgoliaSearch integration to your favorite ORM"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.5.1"])
      s.add_runtime_dependency(%q<algolia>, ["< 3.0.0"])
      s.add_development_dependency(%q<will_paginate>, [">= 2.3.15"])
      s.add_development_dependency(%q<kaminari>, [">= 0"])
      s.add_development_dependency(%q<pagy>, [">= 0"])
      s.add_development_dependency "rake"
      s.add_development_dependency "rdoc"
    else
      s.add_dependency(%q<json>, [">= 1.5.1"])
      s.add_dependency(%q<algolia>, ["< 3.0.0"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.5.1"])
    s.add_dependency(%q<algolia>, ["< 3.0.0"])
  end
end

