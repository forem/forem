# -*- encoding: utf-8 -*-
# stub: carrierwave-bombshelter 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "carrierwave-bombshelter".freeze
  s.version = "0.2.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["DarthSim".freeze]
  s.bindir = "exe".freeze
  s.date = "2016-05-18"
  s.email = ["darthsim@gmail.com".freeze]
  s.homepage = "https://github.com/DarthSim/carrierwave-bombshelter".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Protect your carrierwave from image bombs".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<fog-core>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<fog>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<fog-aws>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<mime-types>.freeze, ["< 3.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.2.0".freeze])
  s.add_runtime_dependency(%q<fastimage>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<carrierwave>.freeze, [">= 0".freeze])
end
