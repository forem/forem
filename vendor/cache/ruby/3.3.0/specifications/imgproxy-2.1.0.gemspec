# -*- encoding: utf-8 -*-
# stub: imgproxy 2.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "imgproxy".freeze
  s.version = "2.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sergey Alexandrovich".freeze]
  s.date = "2022-06-14"
  s.description = "A gem that easily generates imgproxy URLs for your images".freeze
  s.email = "darthsim@gmail.com".freeze
  s.homepage = "https://github.com/imgproxy/imgproxy.rb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "imgproxy URL generator".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<anyway_config>.freeze, [">= 2.0.0".freeze])
  s.add_development_dependency(%q<benchmark-memory>.freeze, ["~> 0.2.0".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, ["~> 3.9.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11.0".freeze])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.5.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.30.1".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.11.1".freeze])
  s.add_development_dependency(%q<aws-sdk-s3>.freeze, ["~> 1.64".freeze])
  s.add_development_dependency(%q<google-cloud-storage>.freeze, ["~> 1.11".freeze])
  s.add_development_dependency(%q<rails>.freeze, ["~> 7.0.3".freeze])
  s.add_development_dependency(%q<shrine>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.4.1".freeze])
end
