# -*- encoding: utf-8 -*-
# stub: rpush 7.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rpush".freeze
  s.version = "7.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rpush/rpush/issues", "changelog_uri" => "https://github.com/rpush/rpush/blob/master/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rpush/rpush" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ian Leitch".freeze]
  s.date = "2022-03-02"
  s.description = "The push notification service for Ruby.".freeze
  s.email = ["port001@gmail.com".freeze]
  s.executables = ["rpush".freeze]
  s.files = ["bin/rpush".freeze]
  s.homepage = "https://github.com/rpush/rpush".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "When upgrading Rpush, don't forget to run `bundle exec rpush init` to get all the latest migrations.\n\nFor details on this specific release, refer to the CHANGELOG.md file.\nhttps://github.com/rpush/rpush/blob/master/CHANGELOG.md\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "The push notification service for Ruby.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<net-http-persistent>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<net-http2>.freeze, ["~> 0.18".freeze, ">= 0.18.3".freeze])
  s.add_runtime_dependency(%q<jwt>.freeze, [">= 1.5.6".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<thor>.freeze, [">= 0.18.1".freeze, "< 2.0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<webpush>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4.0".freeze])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<timecop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<stackprof>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<modis>.freeze, [">= 2.0".freeze])
  s.add_development_dependency(%q<rpush-redis>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<codeclimate-test-reporter>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.12.0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pg>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mysql2>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
end
