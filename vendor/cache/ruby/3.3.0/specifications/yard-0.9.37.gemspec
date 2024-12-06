# -*- encoding: utf-8 -*-
# stub: yard 0.9.37 ruby lib

Gem::Specification.new do |s|
  s.name = "yard".freeze
  s.version = "0.9.37".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "yard.run" => "yri" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Loren Segal".freeze]
  s.date = "2024-09-04"
  s.description = "    YARD is a documentation generation tool for the Ruby programming language.\n    It enables the user to generate consistent, usable documentation that can be\n    exported to a number of formats very easily, and also supports extending for\n    custom Ruby constructs such as custom class level definitions.\n".freeze
  s.email = "lsegal@soen.ca".freeze
  s.executables = ["yard".freeze, "yardoc".freeze, "yri".freeze]
  s.files = ["bin/yard".freeze, "bin/yardoc".freeze, "bin/yri".freeze]
  s.homepage = "http://yardoc.org".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Documentation tool for consistent and usable documentation in Ruby.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version
end
