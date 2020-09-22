# -*- encoding: utf-8 -*-
# stub: omniauth-oauth2 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-oauth2".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Erik Michaels-Ober".freeze, "Tom Milewski".freeze]
  s.date = "2020-09-22"
  s.description = "An abstract OAuth2 strategy for OmniAuth.".freeze
  s.email = ["michael@intridea.com".freeze, "sferik@gmail.com".freeze, "tmilewski@gmail.com".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".rubocop.yml".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.md".freeze, "README.md".freeze, "Rakefile".freeze, "lib/omniauth-oauth2.rb".freeze, "lib/omniauth-oauth2/version.rb".freeze, "lib/omniauth/strategies/oauth2.rb".freeze, "omniauth-oauth2.gemspec".freeze, "spec/helper.rb".freeze, "spec/omniauth/strategies/oauth2_spec.rb".freeze]
  s.homepage = "https://github.com/omniauth/omniauth-oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "An abstract OAuth2 strategy for OmniAuth.".freeze
  s.test_files = ["spec/helper.rb".freeze, "spec/omniauth/strategies/oauth2_spec.rb".freeze]

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<oauth2>.freeze, ["~> 1.4"])
    s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 1.9"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
  else
    s.add_dependency(%q<oauth2>.freeze, ["~> 1.4"])
    s.add_dependency(%q<omniauth>.freeze, ["~> 1.9"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
  end
end
