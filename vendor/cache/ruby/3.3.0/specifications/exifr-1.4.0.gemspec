# -*- encoding: utf-8 -*-
# stub: exifr 1.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "exifr".freeze
  s.version = "1.4.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/remvee/exifr/issues", "changelog_uri" => "https://github.com/remvee/exifr/blob/master/CHANGELOG", "documentation_uri" => "https://remvee.github.io/exifr/api/", "homepage_uri" => "https://remvee.github.io/exifr/", "source_code_uri" => "https://github.com/remvee/exifr" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["R.W. van 't Veer".freeze]
  s.date = "2023-05-26"
  s.description = "EXIF Reader is a module to read EXIF from JPEG and TIFF images.".freeze
  s.email = "exifr@remworks.net".freeze
  s.executables = ["exifr".freeze]
  s.files = ["bin/exifr".freeze]
  s.homepage = "http://github.com/remvee/exifr/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Read EXIF from JPEG and TIFF images".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<test-unit>.freeze, ["= 3.1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12".freeze])
end
