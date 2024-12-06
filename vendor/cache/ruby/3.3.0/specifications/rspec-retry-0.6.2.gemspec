# -*- encoding: utf-8 -*-
# stub: rspec-retry 0.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-retry".freeze
  s.version = "0.6.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yusuke Mito".freeze, "Michael Glass".freeze]
  s.date = "2019-11-21"
  s.description = "retry intermittently failing rspec examples".freeze
  s.email = ["mike@noredink.com".freeze]
  s.homepage = "http://github.com/NoRedInk/rspec-retry".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "retry intermittently failing rspec examples".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rspec-core>.freeze, ["> 3.3".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<byebug>.freeze, ["~> 9.0.6".freeze])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0".freeze])
end
