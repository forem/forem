# -*- encoding: utf-8 -*-
# stub: dogstatsd-ruby 5.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "dogstatsd-ruby".freeze
  s.version = "5.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/DataDog/dogstatsd-ruby/issues", "changelog_uri" => "https://github.com/DataDog/dogstatsd-ruby/blob/v5.6.1/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/dogstatsd-ruby/5.6.1", "source_code_uri" => "https://github.com/DataDog/dogstatsd-ruby/tree/v5.6.1" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rein Henrichs".freeze, "Karim Bogtob".freeze]
  s.date = "2023-09-07"
  s.description = "A Ruby DogStatsd client".freeze
  s.email = "code@datadoghq.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/DataDog/dogstatsd-ruby".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "\nIf you are upgrading from v4.x of the dogstatsd-ruby library, note the major change to the threading model:\nhttps://github.com/DataDog/dogstatsd-ruby#migrating-from-v4x-to-v5x\n\n".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "A Ruby DogStatsd client".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version
end
