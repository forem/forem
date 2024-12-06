# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zonebie/version'

Gem::Specification.new do |gem|
  gem.name          = "zonebie"
  gem.version       = Zonebie::VERSION
  gem.authors       = ['Andy Lindeman', 'Steven Harman', 'Patrick Van Stee']
  gem.email         = ['andy@andylindeman.com', 'steveharman@gmail.com', 'patrickvanstee@gmail.com']
  gem.description   = %q{Runs your tests in a random timezone}
  gem.summary       = %q{Zonebie prevents bugs in code that deals with timezones by randomly assigning a zone on every run}
  gem.homepage      = "https://github.com/alindeman/zonebie"
  gem.license       = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|gem|features)/}) }
  gem.bindir        = "exe"
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0.0'

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.4"
  gem.add_development_dependency "mocha", "~> 0.14.0"

  gem.add_development_dependency "activesupport", "~> 3.0"
  gem.add_development_dependency "tzinfo", "~> 1.2", ">= 1.2.2"
  gem.add_development_dependency "tzinfo-data", ">= 1.2016.1"
end
