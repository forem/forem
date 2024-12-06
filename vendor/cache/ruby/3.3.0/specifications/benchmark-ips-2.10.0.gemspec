# -*- encoding: utf-8 -*-
# stub: benchmark-ips 2.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "benchmark-ips".freeze
  s.version = "2.10.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Evan Phoenix".freeze]
  s.date = "2015-01-12"
  s.description = "A iterations per second enhancement to Benchmark.".freeze
  s.email = ["evan@phx.io".freeze]
  s.extra_rdoc_files = ["History.md".freeze, "LICENSE".freeze, "README.md".freeze]
  s.files = ["History.md".freeze, "LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/evanphx/benchmark-ips".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A iterations per second enhancement to Benchmark.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.4".freeze])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0".freeze])
end
