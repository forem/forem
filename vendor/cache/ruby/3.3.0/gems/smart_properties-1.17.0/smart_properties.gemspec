# -*- encoding: utf-8 -*-
require File.expand_path('../lib/smart_properties/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Konstantin Tennhard"]
  gem.email         = ["me@t6d.de"]
  gem.description   = <<-DESCRIPTION
  SmartProperties are a more flexible and feature-rich alternative to
  traditional Ruby accessors. They provide support for input conversion,
  input validation, specifying default values and presence checking.
  DESCRIPTION
  gem.summary       = %q{SmartProperties – Ruby accessors on steroids}
  gem.homepage      = ""

  gem.metadata = {
    "source_code_uri" => "https://github.com/t6d/smart_properties"
  }

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "smart_properties"
  gem.require_paths = ["lib"]
  gem.version       = SmartProperties::VERSION

  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "rake", "~> 13.0"
  gem.add_development_dependency "pry"
end
