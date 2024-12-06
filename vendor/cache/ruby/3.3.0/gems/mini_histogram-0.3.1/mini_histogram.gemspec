require_relative 'lib/mini_histogram/version'

Gem::Specification.new do |spec|
  spec.name          = "mini_histogram"
  spec.version       = MiniHistogram::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman+foo@gmail.com"]

  spec.summary       = %q{A small gem for building histograms out of Ruby arrays}
  spec.description   = %q{It makes histograms out of Ruby data. How cool is that!? Pretty cool if you ask me.}
  spec.homepage      = "https://github.com/zombocom/mini_histogram"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.1.0")

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "blerg"
  # spec.metadata["changelog_uri"] = "blerg"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "m"
  # Used for comparison testing, but only supports Ruby 2.4+
  # spec.add_development_dependency "enumerable-statistics"
  spec.add_development_dependency "benchmark-ips"
end
