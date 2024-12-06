# -*- encoding: utf-8 -*-
# stub: excon 0.104.0 ruby lib

Gem::Specification.new do |s|
  s.name = "excon".freeze
  s.version = "0.104.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/excon/excon/issues", "changelog_uri" => "https://github.com/excon/excon/blob/master/changelog.txt", "documentation_uri" => "https://github.com/excon/excon/blob/master/README.md", "homepage_uri" => "https://github.com/excon/excon", "source_code_uri" => "https://github.com/excon/excon", "wiki_uri" => "https://github.com/excon/excon/wiki" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["dpiddy (Dan Peterson)".freeze, "geemus (Wesley Beary)".freeze, "nextmat (Matt Sanders)".freeze]
  s.date = "2023-09-29"
  s.description = "EXtended http(s) CONnections".freeze
  s.email = "geemus@gmail.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "CONTRIBUTORS.md".freeze, "CONTRIBUTING.md".freeze]
  s.files = ["CONTRIBUTING.md".freeze, "CONTRIBUTORS.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/excon/excon".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "speed, persistence, http(s)".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, [">= 3.5.0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<delorean>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<eventmachine>.freeze, [">= 1.0.4".freeze])
  s.add_development_dependency(%q<open4>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<shindo>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sinatra>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sinatra-contrib>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<json>.freeze, [">= 1.8.5".freeze])
  s.add_development_dependency(%q<puma>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webrick>.freeze, [">= 0".freeze])
end
