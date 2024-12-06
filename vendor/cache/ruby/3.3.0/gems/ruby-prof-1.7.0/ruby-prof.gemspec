# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "ruby-prof/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-prof"

  spec.homepage = "https://github.com/ruby-prof/ruby-prof/"
  spec.summary = "Fast Ruby profiler"
  spec.description = <<-EOF
ruby-prof is a fast code profiler for Ruby. It is a C extension and
therefore is many times faster than the standard Ruby profiler. It
supports both flat and graph profiles.  For each method, graph profiles
show how long the method ran, which methods called it and which
methods it called. RubyProf generate both text and html and can output
it to standard out or to a file.
EOF
  spec.license = 'BSD-2-Clause'
  spec.version = RubyProf::VERSION

  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/ruby-prof/ruby-prof/issues",
    "changelog_uri"     => "https://github.com/ruby-prof/ruby-prof/blob/master/CHANGES",
    "documentation_uri" => "https://ruby-prof.github.io/",
    "source_code_uri"   => "https://github.com/ruby-prof/ruby-prof/tree/v#{spec.version}",
  }

  spec.author = "Shugo Maeda, Charlie Savage, Roger Pack, Stefan Kaes"
  spec.email = "shugo@ruby-lang.org, cfis@savagexi.com, rogerdpack@gmail.com, skaes@railsexpress.de"
  spec.platform = Gem::Platform::RUBY
  spec.require_path = "lib"
  spec.bindir = "bin"
  spec.executables = ["ruby-prof", "ruby-prof-check-trace"]
  spec.extensions = ["ext/ruby_prof/extconf.rb"]
  spec.files = Dir['CHANGES',
                   'LICENSE',
                   'Rakefile',
                   'README.md',
                   'ruby-prof.gemspec',
                   'bin/ruby-prof',
                   'bin/ruby-prof-check-trace',
                   'doc/**/*',
                   'examples/*',
                   'ext/ruby_prof/extconf.rb',
                   'ext/ruby_prof/*.c',
                   'ext/ruby_prof/*.h',
                   'ext/ruby_prof/vc/*.sln',
                   'ext/ruby_prof/vc/*.vcxproj',
                   'lib/ruby-prof.rb',
                   'lib/unprof.rb',
                   'lib/ruby-prof/*.rb',
                   'lib/ruby-prof/assets/*',
                   'lib/ruby-prof/profile/*.rb',
                   'lib/ruby-prof/printers/*.rb',
                   'test/*.rb']

  spec.test_files = Dir["test/test_*.rb"]
  spec.required_ruby_version = '>= 3.0.0'
  spec.date = Time.now.strftime('%Y-%m-%d')
  spec.homepage = 'https://github.com/ruby-prof/ruby-prof'
  spec.add_development_dependency('minitest')
  spec.add_development_dependency('rake-compiler')
end
