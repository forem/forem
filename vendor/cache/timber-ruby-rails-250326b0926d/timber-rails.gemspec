# -*- encoding: utf-8 -*-
# stub: timber-rails 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "timber-rails".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/timberio/timber-ruby-rails/blob/master/README.md", "homepage_uri" => "https://docs.timber.io/languages/ruby/", "source_code_uri" => "https://github.com/timberio/timber-ruby-rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Timber Technologies, Inc.".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-06-01"
  s.email = ["hi@timber.io".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.md".freeze, "README.md".freeze, "Rakefile".freeze, "bin/console".freeze, "bin/setup".freeze, "gemfiles/rails-3.0.gemfile".freeze, "gemfiles/rails-3.1.gemfile".freeze, "gemfiles/rails-3.2.gemfile".freeze, "gemfiles/rails-4.0.gemfile".freeze, "gemfiles/rails-4.1.gemfile".freeze, "gemfiles/rails-4.2.gemfile".freeze, "gemfiles/rails-5.0.gemfile".freeze, "gemfiles/rails-5.1.gemfile".freeze, "gemfiles/rails-5.2.gemfile".freeze, "gemfiles/rails-6.0.gemfile".freeze, "gemfiles/rails-edge.gemfile".freeze, "lib/timber-rails.rb".freeze, "lib/timber-rails/action_controller.rb".freeze, "lib/timber-rails/action_controller/log_subscriber.rb".freeze, "lib/timber-rails/action_controller/log_subscriber/timber_log_subscriber.rb".freeze, "lib/timber-rails/action_dispatch.rb".freeze, "lib/timber-rails/action_dispatch/debug_exceptions.rb".freeze, "lib/timber-rails/action_view.rb".freeze, "lib/timber-rails/action_view/log_subscriber.rb".freeze, "lib/timber-rails/action_view/log_subscriber/timber_log_subscriber.rb".freeze, "lib/timber-rails/active_record.rb".freeze, "lib/timber-rails/active_record/log_subscriber.rb".freeze, "lib/timber-rails/active_record/log_subscriber/timber_log_subscriber.rb".freeze, "lib/timber-rails/active_support_log_subscriber.rb".freeze, "lib/timber-rails/config.rb".freeze, "lib/timber-rails/config/action_controller.rb".freeze, "lib/timber-rails/config/action_view.rb".freeze, "lib/timber-rails/config/active_record.rb".freeze, "lib/timber-rails/error_event.rb".freeze, "lib/timber-rails/logger.rb".freeze, "lib/timber-rails/overrides.rb".freeze, "lib/timber-rails/overrides/active_support_3_tagged_logging.rb".freeze, "lib/timber-rails/overrides/active_support_buffered_logger.rb".freeze, "lib/timber-rails/overrides/active_support_tagged_logging.rb".freeze, "lib/timber-rails/overrides/lograge.rb".freeze, "lib/timber-rails/overrides/rails_stdout_logging.rb".freeze, "lib/timber-rails/rack_logger.rb".freeze, "lib/timber-rails/railtie.rb".freeze, "lib/timber-rails/session_context.rb".freeze, "lib/timber-rails/version.rb".freeze, "timber-rails.gemspec".freeze]
  s.homepage = "https://docs.timber.io/languages/ruby/".freeze
  s.licenses = ["ISC".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Timber.io Rails integration".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 3.0.0"])
    s.add_runtime_dependency(%q<timber>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<timber-rack>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0.8"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_development_dependency(%q<bundler-audit>.freeze, [">= 0"])
    s.add_development_dependency(%q<rails_stdout_logging>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_development_dependency(%q<timecop>.freeze, [">= 0"])
    s.add_development_dependency(%q<sqlite3>.freeze, ["= 1.3.13"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 2.3"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<timber>.freeze, ["~> 3.0"])
    s.add_dependency(%q<timber-rack>.freeze, ["~> 1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0.8"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<bundler-audit>.freeze, [">= 0"])
    s.add_dependency(%q<rails_stdout_logging>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_dependency(%q<timecop>.freeze, [">= 0"])
    s.add_dependency(%q<sqlite3>.freeze, ["= 1.3.13"])
    s.add_dependency(%q<webmock>.freeze, ["~> 2.3"])
  end
end
