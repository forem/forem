# -*- encoding: utf-8 -*-
# stub: counter_culture 3.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "counter_culture".freeze
  s.version = "3.5.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Magnus von Koeller".freeze]
  s.bindir = "exe".freeze
  s.date = "2024-02-17"
  s.description = "counter_culture provides turbo-charged counter caches that are kept up-to-date not just on create and destroy, that support multiple levels of indirection through relationships, allow dynamic column names and that avoid deadlocks by updating in the after_commit callback.".freeze
  s.email = ["magnus@vonkoeller.de".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/magnusvk/counter_culture".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Turbo-charged counter caches for your Rails app.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, ["> 2.0.0".freeze])
  s.add_development_dependency(%q<awesome_print>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 1.1.1".freeze])
  s.add_development_dependency(%q<discard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<paper_trail>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<paranoia>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<after_commit_action>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 4.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 6.3.1".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<rspec-extra-formatters>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16.1".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
end
