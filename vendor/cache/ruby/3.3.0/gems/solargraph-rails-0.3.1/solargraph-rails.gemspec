
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "solargraph/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "solargraph-rails"
  spec.version       = Solargraph::Rails::VERSION
  spec.authors       = ["Fritz Meissner"]
  spec.email         = ["fritz.meissner@gmail.com"]

  spec.summary       = %q{Solargraph plugin that adds Rails-specific code through a Convention}
  spec.description   = %q{Add reflection on ActiveModel dynamic attributes that will be created at runtime}
  spec.homepage      = 'https://github.com/iftheshoefritz/solargraph-rails'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2.10"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "solargraph", ">= 0.41.1"
  spec.add_runtime_dependency "activesupport"
end
