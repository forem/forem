require_relative "lib/rss/version"

Gem::Specification.new do |spec|
  spec.name          = "rss"
  spec.version       = RSS::VERSION
  spec.authors       = ["Kouhei Sutou"]
  spec.email         = ["kou@cozmixng.org"]

  spec.summary       = %q{Family of libraries that support various formats of XML "feeds".}
  spec.description   = %q{Family of libraries that support various formats of XML "feeds".}
  spec.homepage      = "https://github.com/ruby/rss"
  spec.license       = "BSD-2-Clause"

  spec.files = [
    "#{spec.name}.gemspec",
    "Gemfile",
    "LICENSE.txt",
    "NEWS.md",
    "README.md",
    "Rakefile",
  ]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.test_files += Dir.glob("test/**/*")
  spec.require_paths = ["lib"]

  spec.add_dependency "rexml"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit"
end
