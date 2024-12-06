lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'better_errors/version'

Gem::Specification.new do |s|
  s.name          = "better_errors"
  s.version       = BetterErrors::VERSION
  s.authors       = ["Hailey Somerville"]
  s.email         = ["hailey@hailey.lol"]
  s.description   = %q{Provides a better error page for Rails and other Rack apps. Includes source code inspection, a live REPL and local/instance variable inspection for all stack frames.}
  s.summary       = %q{Better error page for Rails and other Rack apps}
  s.homepage      = "https://github.com/BetterErrors/better_errors"
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f|
    f.match(%r{^((test|spec|features|feature-screenshots)/|Rakefile)|\.scss$})
  } + %w[lib/better_errors/templates/main.css]

  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.0.0"

  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "rspec-html-matchers"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "yard"
  s.add_development_dependency "sassc"
  # kramdown 2.1 requires Ruby 2.3+
  s.add_development_dependency "kramdown", (RUBY_VERSION < '2.3' ? '< 2.0.0' : '> 2.0.0')
  # simplecov and coveralls must not be included here. See the Gemfiles instead.

  s.add_dependency "erubi", ">= 1.0.0"
  s.add_dependency "rouge", ">= 1.0.0"
  s.add_dependency "rack", ">= 0.9.0"

  # optional dependencies:
  # s.add_dependency "binding_of_caller"
  # s.add_dependency "pry"
  
  if s.respond_to?(:metadata)
    s.metadata['changelog_uri'] = 'https://github.com/BetterErrors/better_errors/releases'
    s.metadata['source_code_uri'] = 'https://github.com/BetterErrors/better_errors'
    s.metadata['bug_tracker_uri'] = 'https://github.com/BetterErrors/better_errors/issues'
  else
    puts "Your RubyGems does not support metadata. Update if you'd like to make a release."
  end
end
