
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "backport/version"

Gem::Specification.new do |spec|
  spec.name          = "backport"
  spec.version       = Backport::VERSION
  spec.authors       = ["Fred Snyder"]
  spec.email         = ["fsnyder@castwide.com"]

  spec.summary       = %q{A pure Ruby library for event-driven IO}
  spec.homepage      = "http://github.com/castwide/backport"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1'

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.14"
end
