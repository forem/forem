# -*- encoding: utf-8 -*-
# stub: omniauth 1.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth".freeze
  s.version = "1.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Erik Michaels-Ober".freeze, "Tom Milewski".freeze]
  s.date = "2020-09-22"
  s.description = "A generalized Rack framework for multiple-provider authentication.".freeze
  s.email = ["michael@intridea.com".freeze, "sferik@gmail.com".freeze, "tmilewski@gmail.com".freeze]
  s.files = [".github/ISSUE_TEMPLATE.md".freeze, ".gitignore".freeze, ".rspec".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, ".yardopts".freeze, "Gemfile".freeze, "LICENSE.md".freeze, "README.md".freeze, "Rakefile".freeze, "lib/omniauth.rb".freeze, "lib/omniauth/auth_hash.rb".freeze, "lib/omniauth/builder.rb".freeze, "lib/omniauth/failure_endpoint.rb".freeze, "lib/omniauth/form.css".freeze, "lib/omniauth/form.rb".freeze, "lib/omniauth/key_store.rb".freeze, "lib/omniauth/strategies/developer.rb".freeze, "lib/omniauth/strategy.rb".freeze, "lib/omniauth/test.rb".freeze, "lib/omniauth/test/phony_session.rb".freeze, "lib/omniauth/test/strategy_macros.rb".freeze, "lib/omniauth/test/strategy_test_case.rb".freeze, "lib/omniauth/version.rb".freeze, "omniauth.gemspec".freeze]
  s.homepage = "https://github.com/omniauth/omniauth".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A generalized Rack framework for multiple-provider authentication.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<hashie>.freeze, [">= 3.4.6"])
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.6.2", "< 3"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
  else
    s.add_dependency(%q<hashie>.freeze, [">= 3.4.6"])
    s.add_dependency(%q<rack>.freeze, [">= 1.6.2", "< 3"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
  end
end
