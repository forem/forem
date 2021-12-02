# -*- encoding: utf-8 -*-
# stub: cypress-rails 0.5.3 ruby lib

Gem::Specification.new do |s|
  s.name = "cypress-rails".freeze
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Searls".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-10-22"
  s.email = ["searls@gmail.com".freeze]
  s.executables = ["cypress-rails".freeze]
  s.files = [".github/workflows/main.yml".freeze, ".gitignore".freeze, ".standard.yml".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "cypress-rails.gemspec".freeze, "exe/cypress-rails".freeze, "lib/cypress-rails.rb".freeze, "lib/cypress-rails/config.rb".freeze, "lib/cypress-rails/env.rb".freeze, "lib/cypress-rails/finds_bin.rb".freeze, "lib/cypress-rails/init.rb".freeze, "lib/cypress-rails/initializer_hooks.rb".freeze, "lib/cypress-rails/launches_cypress.rb".freeze, "lib/cypress-rails/manages_transactions.rb".freeze, "lib/cypress-rails/open.rb".freeze, "lib/cypress-rails/railtie.rb".freeze, "lib/cypress-rails/rake.rb".freeze, "lib/cypress-rails/resets_state.rb".freeze, "lib/cypress-rails/run.rb".freeze, "lib/cypress-rails/run_knapsack.rb".freeze, "lib/cypress-rails/server.rb".freeze, "lib/cypress-rails/server/checker.rb".freeze, "lib/cypress-rails/server/middleware.rb".freeze, "lib/cypress-rails/server/puma.rb".freeze, "lib/cypress-rails/server/timer.rb".freeze, "lib/cypress-rails/starts_rails_server.rb".freeze, "lib/cypress-rails/tracks_resets.rb".freeze, "lib/cypress-rails/version.rb".freeze, "script/test".freeze, "script/test_example_app".freeze]
  s.homepage = "https://github.com/testdouble/cypress-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.22".freeze
  s.summary = "Helps you write Cypress tests of your Rails app".freeze

  s.installed_by_version = "3.2.22" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<railties>.freeze, [">= 5.2.0"])
    s.add_runtime_dependency(%q<puma>.freeze, [">= 3.8.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<standard>.freeze, [">= 0.2.0"])
  else
    s.add_dependency(%q<railties>.freeze, [">= 5.2.0"])
    s.add_dependency(%q<puma>.freeze, [">= 3.8.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<standard>.freeze, [">= 0.2.0"])
  end
end
