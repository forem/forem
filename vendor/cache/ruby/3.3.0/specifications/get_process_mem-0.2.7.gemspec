# -*- encoding: utf-8 -*-
# stub: get_process_mem 0.2.7 ruby lib

Gem::Specification.new do |s|
  s.name = "get_process_mem".freeze
  s.version = "0.2.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Richard Schneeman".freeze]
  s.date = "2020-08-27"
  s.description = " Get memory usage of a process in Ruby ".freeze
  s.email = ["richard.schneeman+rubygems@gmail.com".freeze]
  s.homepage = "https://github.com/schneems/get_process_mem".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Use GetProcessMem to find out the amount of RAM used by any process".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<sys-proctable>.freeze, ["~> 1.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["~> 3".freeze])
end
