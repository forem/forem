$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'excon/version'

Gem::Specification.new do |s|
  s.name             = 'excon'
  s.version          = Excon::VERSION
  s.summary          = "speed, persistence, http(s)"
  s.description      = "EXtended http(s) CONnections"
  s.authors          = ["dpiddy (Dan Peterson)", "geemus (Wesley Beary)", "nextmat (Matt Sanders)"]
  s.email            = 'geemus@gmail.com'
  s.homepage         = 'https://github.com/excon/excon'
  s.license          = 'MIT'
  s.rdoc_options     = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md CONTRIBUTORS.md CONTRIBUTING.md]
  s.files            = `git ls-files -- data/* lib/*`.split("\n") + [
    "CONTRIBUTING.md",
    "CONTRIBUTORS.md",
    "LICENSE.md",
    "README.md",
    "excon.gemspec"
  ]

  s.add_development_dependency('rspec', '>= 3.5.0')
  s.add_development_dependency('activesupport')
  s.add_development_dependency('delorean')
  s.add_development_dependency('eventmachine', '>= 1.0.4')
  s.add_development_dependency('open4')
  s.add_development_dependency('rake')
  s.add_development_dependency('shindo')
  s.add_development_dependency('sinatra')
  s.add_development_dependency('sinatra-contrib')
  s.add_development_dependency('json', '>= 1.8.5')
  s.add_development_dependency('puma')
  s.add_development_dependency('webrick')

  s.metadata = {
    'homepage_uri'      => 'https://github.com/excon/excon',
    'bug_tracker_uri'   => 'https://github.com/excon/excon/issues',
    'changelog_uri'     => 'https://github.com/excon/excon/blob/master/changelog.txt',
    'documentation_uri' => 'https://github.com/excon/excon/blob/master/README.md',
    'source_code_uri'   => 'https://github.com/excon/excon',
    'wiki_uri'          => 'https://github.com/excon/excon/wiki'
  }
end
