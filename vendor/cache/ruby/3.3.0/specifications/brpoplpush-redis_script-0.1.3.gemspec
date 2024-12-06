# -*- encoding: utf-8 -*-
# stub: brpoplpush-redis_script 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "brpoplpush-redis_script".freeze
  s.version = "0.1.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script/CHANGELOG.md", "homepage_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikael Henriksson".freeze, "Mauro Berlanda".freeze]
  s.date = "2022-11-07"
  s.description = "Bring your own LUA scripts into redis.".freeze
  s.email = ["mikael@mhenrixon.com".freeze, "mauro.berlanda@gmail.com".freeze]
  s.homepage = "https://github.com/brpoplpush/brpoplpush-redis_script".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Bring your own LUA scripts into redis.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze, ">= 1.0.5".freeze])
  s.add_runtime_dependency(%q<redis>.freeze, [">= 1.0".freeze, "< 6".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7".freeze])
  s.add_development_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14".freeze])
  s.add_development_dependency(%q<github-markup>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.18".freeze])
  s.add_development_dependency(%q<gem-release>.freeze, ["~> 2.0".freeze])
end
