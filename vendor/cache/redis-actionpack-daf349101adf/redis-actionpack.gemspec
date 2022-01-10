# -*- encoding: utf-8 -*-
# stub: redis-actionpack 5.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-actionpack".freeze
  s.version = "5.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Luca Guidi".freeze]
  s.date = "2022-01-10"
  s.description = "Redis session store for ActionPack. Used for storing the Rails session in Redis.".freeze
  s.email = ["me@lucaguidi.com".freeze]
  s.files = [".github/auto-assign-issues.yml".freeze, ".gitignore".freeze, ".travis.yml".freeze, "Appraisals".freeze, "CHANGELOG.md".freeze, "CODEOWNERS".freeze, "Gemfile".freeze, "MIT-LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "bin/bundler-version-options.rb".freeze, "gemfiles/rails_5.0.x.gemfile".freeze, "gemfiles/rails_5.1.x.gemfile".freeze, "gemfiles/rails_5.2.x.gemfile".freeze, "gemfiles/rails_6.0.x.gemfile".freeze, "lib/action_dispatch/middleware/session/redis_store.rb".freeze, "lib/redis-actionpack.rb".freeze, "lib/redis/actionpack/version.rb".freeze, "redis-actionpack.gemspec".freeze, "test/dummy/.gitignore".freeze, "test/dummy/Rakefile".freeze, "test/dummy/app/controllers/test_controller.rb".freeze, "test/dummy/app/views/test/get_session_id.html.erb".freeze, "test/dummy/app/views/test/get_session_value.html.erb".freeze, "test/dummy/config.ru".freeze, "test/dummy/config/application.rb".freeze, "test/dummy/config/boot.rb".freeze, "test/dummy/config/environment.rb".freeze, "test/dummy/config/routes.rb".freeze, "test/dummy/script/rails".freeze, "test/fixtures/session_autoload_test/session_autoload_test/foo.rb".freeze, "test/gemfiles/Gemfile.rails-6.0.x".freeze, "test/integration/redis_store_integration_test.rb".freeze, "test/test_helper.rb".freeze]
  s.homepage = "http://redis-store.org/redis-actionpack".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.2.22".freeze
  s.summary = "Redis session store for ActionPack".freeze
  s.test_files = ["test/dummy/.gitignore".freeze, "test/dummy/Rakefile".freeze, "test/dummy/app/controllers/test_controller.rb".freeze, "test/dummy/app/views/test/get_session_id.html.erb".freeze, "test/dummy/app/views/test/get_session_value.html.erb".freeze, "test/dummy/config.ru".freeze, "test/dummy/config/application.rb".freeze, "test/dummy/config/boot.rb".freeze, "test/dummy/config/environment.rb".freeze, "test/dummy/config/routes.rb".freeze, "test/dummy/script/rails".freeze, "test/fixtures/session_autoload_test/session_autoload_test/foo.rb".freeze, "test/gemfiles/Gemfile.rails-6.0.x".freeze, "test/integration/redis_store_integration_test.rb".freeze, "test/test_helper.rb".freeze]

  s.installed_by_version = "3.2.22" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<redis-store>.freeze, [">= 1.1.0", "< 2"])
    s.add_runtime_dependency(%q<redis-rack>.freeze, [">= 2.1.0", "< 3"])
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5", "< 8"])
  else
    s.add_dependency(%q<redis-store>.freeze, [">= 1.1.0", "< 2"])
    s.add_dependency(%q<redis-rack>.freeze, [">= 2.1.0", "< 3"])
    s.add_dependency(%q<actionpack>.freeze, [">= 5", "< 8"])
  end
end
