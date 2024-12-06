require File.expand_path("../lib/omniauth-oauth/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Bleigh", "Erik Michaels-Ober"]
  gem.email         = ["michael@intridea.com", "sferik@gmail.com"]
  gem.description   = "A generic OAuth (1.0/1.0a) strategy for OmniAuth."
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/intridea/omniauth-oauth"
  gem.license       = "MIT"

  gem.add_dependency "omniauth", ">= 1.0", "< 3"
  gem.add_dependency "oauth"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "omniauth-oauth"
  gem.require_paths = ["lib"]
  gem.version       = OmniAuth::OAuth::VERSION
end
