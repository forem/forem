require File.expand_path('../lib/meta_inspector/version', __FILE__)

Gem::Specification.new do |gem|
  gem.author        = "Jaime Iniesta"
  gem.email         = "jaimeiniesta@gmail.com"
  gem.description   = %q{MetaInspector lets you scrape a web page and get its links, images, texts, meta tags...}
  gem.summary       = %q{MetaInspector is a ruby gem for web scraping purposes, that returns metadata from a given URL}
  gem.homepage      = "https://github.com/jaimeiniesta/metainspector"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {spec}/*`.split("\n")
  gem.name          = "metainspector"
  gem.require_paths = ["lib"]
  gem.version       = MetaInspector::VERSION

  gem.add_dependency 'nokogiri', '~> 1.13'
  gem.add_dependency 'faraday', '~> 2.5'
  gem.add_dependency 'faraday-cookie_jar', '~> 0.0'
  gem.add_dependency 'faraday-encoding', '~> 0.0'
  gem.add_dependency 'faraday-follow_redirects', '~> 0.3'
  gem.add_dependency 'faraday-gzip', '>= 0.1', '< 2.0'
  gem.add_dependency 'faraday-http-cache', '~> 2.5'
  gem.add_dependency 'faraday-retry', '~> 2.0'
  gem.add_dependency 'addressable', '~> 2.8.4'
  gem.add_dependency 'fastimage', '~> 2.2'
  gem.add_dependency 'nesty', '~> 1.0'

  gem.add_development_dependency 'rspec', '~> 3.11'
  gem.add_development_dependency 'webmock', '~> 3.17'
  gem.add_development_dependency 'awesome_print', '~> 1.9'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'pry', '~> 0.14'
  gem.add_development_dependency 'puma', '~> 6.2.2'
  gem.add_development_dependency 'rubocop', '~> 1.34'
  gem.add_development_dependency 'resolv', '~> 0.2.2'
  gem.add_development_dependency 'sinatra', '~> 3.0.6'
end
