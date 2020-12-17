# -*- encoding: utf-8 -*-
# stub: acts_as_follower 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "acts_as_follower".freeze
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tom Cocca".freeze]
  s.date = "2020-12-17"
  s.description = "acts_as_follower is a Rubygem to allow any model to follow any other model. This is accomplished through a double polymorphic relationship on the Follow model. There is also built in support for blocking/un-blocking follow records. Main uses would be for Users to follow other Users or for Users to follow Books, etc\u2026 (Basically, to develop the type of follow system that GitHub has)".freeze
  s.email = ["tom dot cocca at gmail dot com".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "MIT-LICENSE".freeze, "README.rdoc".freeze, "Rakefile".freeze, "acts_as_follower.gemspec".freeze, "init.rb".freeze, "lib/acts_as_follower.rb".freeze, "lib/acts_as_follower/follow_scopes.rb".freeze, "lib/acts_as_follower/followable.rb".freeze, "lib/acts_as_follower/follower.rb".freeze, "lib/acts_as_follower/follower_lib.rb".freeze, "lib/acts_as_follower/railtie.rb".freeze, "lib/acts_as_follower/version.rb".freeze, "lib/generators/USAGE".freeze, "lib/generators/acts_as_follower_generator.rb".freeze, "lib/generators/templates/migration.rb".freeze, "lib/generators/templates/model.rb".freeze, "test/README".freeze, "test/acts_as_followable_test.rb".freeze, "test/acts_as_follower_test.rb".freeze, "test/dummy30/Gemfile".freeze, "test/dummy30/Rakefile".freeze, "test/dummy30/app/models/application_record.rb".freeze, "test/dummy30/app/models/band.rb".freeze, "test/dummy30/app/models/band/punk.rb".freeze, "test/dummy30/app/models/band/punk/pop_punk.rb".freeze, "test/dummy30/app/models/custom_record.rb".freeze, "test/dummy30/app/models/some.rb".freeze, "test/dummy30/app/models/user.rb".freeze, "test/dummy30/config.ru".freeze, "test/dummy30/config/application.rb".freeze, "test/dummy30/config/boot.rb".freeze, "test/dummy30/config/database.yml".freeze, "test/dummy30/config/environment.rb".freeze, "test/dummy30/config/environments/development.rb".freeze, "test/dummy30/config/environments/test.rb".freeze, "test/dummy30/config/initializers/backtrace_silencers.rb".freeze, "test/dummy30/config/initializers/inflections.rb".freeze, "test/dummy30/config/initializers/secret_token.rb".freeze, "test/dummy30/config/initializers/session_store.rb".freeze, "test/dummy30/config/locales/en.yml".freeze, "test/dummy30/config/routes.rb".freeze, "test/factories/bands.rb".freeze, "test/factories/somes.rb".freeze, "test/factories/users.rb".freeze, "test/follow_test.rb".freeze, "test/schema.rb".freeze, "test/test_helper.rb".freeze]
  s.homepage = "https://github.com/tcocca/acts_as_follower".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "A Rubygem to add Follow functionality for ActiveRecord models".freeze
  s.test_files = ["test/README".freeze, "test/acts_as_followable_test.rb".freeze, "test/acts_as_follower_test.rb".freeze, "test/dummy30/Gemfile".freeze, "test/dummy30/Rakefile".freeze, "test/dummy30/app/models/application_record.rb".freeze, "test/dummy30/app/models/band.rb".freeze, "test/dummy30/app/models/band/punk.rb".freeze, "test/dummy30/app/models/band/punk/pop_punk.rb".freeze, "test/dummy30/app/models/custom_record.rb".freeze, "test/dummy30/app/models/some.rb".freeze, "test/dummy30/app/models/user.rb".freeze, "test/dummy30/config.ru".freeze, "test/dummy30/config/application.rb".freeze, "test/dummy30/config/boot.rb".freeze, "test/dummy30/config/database.yml".freeze, "test/dummy30/config/environment.rb".freeze, "test/dummy30/config/environments/development.rb".freeze, "test/dummy30/config/environments/test.rb".freeze, "test/dummy30/config/initializers/backtrace_silencers.rb".freeze, "test/dummy30/config/initializers/inflections.rb".freeze, "test/dummy30/config/initializers/secret_token.rb".freeze, "test/dummy30/config/initializers/session_store.rb".freeze, "test/dummy30/config/locales/en.yml".freeze, "test/dummy30/config/routes.rb".freeze, "test/factories/bands.rb".freeze, "test/factories/somes.rb".freeze, "test/factories/users.rb".freeze, "test/follow_test.rb".freeze, "test/schema.rb".freeze, "test/test_helper.rb".freeze]

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.0"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_development_dependency(%q<shoulda_create>.freeze, [">= 0"])
    s.add_development_dependency(%q<shoulda>.freeze, [">= 3.5.0"])
    s.add_development_dependency(%q<factory_girl>.freeze, [">= 4.2.0"])
    s.add_development_dependency(%q<rails>.freeze, [">= 4.0"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 4.0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<shoulda_create>.freeze, [">= 0"])
    s.add_dependency(%q<shoulda>.freeze, [">= 3.5.0"])
    s.add_dependency(%q<factory_girl>.freeze, [">= 4.2.0"])
    s.add_dependency(%q<rails>.freeze, [">= 4.0"])
  end
end
