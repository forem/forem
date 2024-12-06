# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inline_svg/version'

Gem::Specification.new do |spec|
  spec.name          = "inline_svg"
  spec.version       = InlineSvg::VERSION
  spec.authors       = ["James Martin"]
  spec.email         = ["inline_svg@jmrtn.com"]
  spec.summary       = %q{Embeds an SVG document, inline.}
  spec.description   = %q{Get an SVG into your view and then style it with CSS.}
  spec.homepage      = "https://github.com/jamesmartin/inline_svg"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "rspec_junit_formatter", "0.2.2"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rubocop"

  spec.add_runtime_dependency "activesupport", ">= 3.0"
  spec.add_runtime_dependency "nokogiri", ">= 1.6"
end
