# -*- encoding: utf-8 -*-
# stub: oauth2 1.4.3 ruby lib

Gem::Specification.new do |s|
  s.name = "oauth2".freeze
  s.version = "1.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/oauth-xx/oauth2/issues", "changelog_uri" => "https://github.com/oauth-xx/oauth2/blob/v1.4.3/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/oauth2/1.4.3", "source_code_uri" => "https://github.com/oauth-xx/oauth2/tree/v1.4.3", "wiki_uri" => "https://github.com/oauth-xx/oauth2/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Peter Boling".freeze, "Michael Bleigh".freeze, "Erik Michaels-Ober".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-09-22"
  s.description = "A Ruby wrapper for the OAuth 2.0 protocol built with a similar style to the original OAuth spec.".freeze
  s.email = ["peter.boling@gmail.com".freeze]
  s.files = [".gitignore".freeze, ".jrubyrc".freeze, ".rspec".freeze, ".rubocop.yml".freeze, ".rubocop_rspec.yml".freeze, ".rubocop_todo.yml".freeze, ".ruby-version".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "CODE_OF_CONDUCT.md".freeze, "CONTRIBUTING.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "gemfiles/jruby_1.7.gemfile".freeze, "gemfiles/jruby_9.0.gemfile".freeze, "gemfiles/jruby_9.1.gemfile".freeze, "gemfiles/jruby_9.2.gemfile".freeze, "gemfiles/jruby_head.gemfile".freeze, "gemfiles/ruby_1.9.gemfile".freeze, "gemfiles/ruby_2.0.gemfile".freeze, "gemfiles/ruby_2.1.gemfile".freeze, "gemfiles/ruby_2.2.gemfile".freeze, "gemfiles/ruby_2.3.gemfile".freeze, "gemfiles/ruby_2.4.gemfile".freeze, "gemfiles/ruby_2.5.gemfile".freeze, "gemfiles/ruby_2.6.gemfile".freeze, "gemfiles/ruby_2.7.gemfile".freeze, "gemfiles/ruby_head.gemfile".freeze, "gemfiles/truffleruby.gemfile".freeze, "lib/oauth2.rb".freeze, "lib/oauth2/access_token.rb".freeze, "lib/oauth2/authenticator.rb".freeze, "lib/oauth2/client.rb".freeze, "lib/oauth2/error.rb".freeze, "lib/oauth2/mac_token.rb".freeze, "lib/oauth2/response.rb".freeze, "lib/oauth2/snaky_hash.rb".freeze, "lib/oauth2/strategy/assertion.rb".freeze, "lib/oauth2/strategy/auth_code.rb".freeze, "lib/oauth2/strategy/base.rb".freeze, "lib/oauth2/strategy/client_credentials.rb".freeze, "lib/oauth2/strategy/implicit.rb".freeze, "lib/oauth2/strategy/password.rb".freeze, "lib/oauth2/version.rb".freeze, "oauth2.gemspec".freeze]
  s.homepage = "https://github.com/oauth-xx/oauth2".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A Ruby wrapper for the OAuth 2.0 protocol.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<faraday>.freeze, [">= 0.8", "< 2.0"])
    s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.0", "< 3.0"])
    s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.3"])
    s.add_runtime_dependency(%q<multi_xml>.freeze, ["~> 0.5"])
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.2", "< 3"])
    s.add_development_dependency(%q<addressable>.freeze, ["~> 2.3"])
    s.add_development_dependency(%q<backports>.freeze, ["~> 3.11"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.16"])
    s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<rake>.freeze, [">= 11"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 5.0", "< 7"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<rspec-stubbed_env>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-pending_for>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-block_is_expected>.freeze, [">= 0"])
    s.add_development_dependency(%q<silent_stream>.freeze, [">= 0"])
    s.add_development_dependency(%q<wwtd>.freeze, [">= 0"])
  else
    s.add_dependency(%q<faraday>.freeze, [">= 0.8", "< 2.0"])
    s.add_dependency(%q<jwt>.freeze, [">= 1.0", "< 3.0"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.3"])
    s.add_dependency(%q<multi_xml>.freeze, ["~> 0.5"])
    s.add_dependency(%q<rack>.freeze, [">= 1.2", "< 3"])
    s.add_dependency(%q<addressable>.freeze, ["~> 2.3"])
    s.add_dependency(%q<backports>.freeze, ["~> 3.11"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.16"])
    s.add_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_dependency(%q<rake>.freeze, [">= 11"])
    s.add_dependency(%q<rdoc>.freeze, [">= 5.0", "< 7"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rspec-stubbed_env>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-pending_for>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-block_is_expected>.freeze, [">= 0"])
    s.add_dependency(%q<silent_stream>.freeze, [">= 0"])
    s.add_dependency(%q<wwtd>.freeze, [">= 0"])
  end
end
