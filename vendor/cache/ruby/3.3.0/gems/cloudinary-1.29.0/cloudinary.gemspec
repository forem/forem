# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cloudinary/version"

Gem::Specification.new do |s|
  s.name        = "cloudinary"
  s.version     = Cloudinary::VERSION
  s.authors     = ["Nadav Soferman","Itai Lahan","Tal Lev-Ami"]
  s.email       = ["nadav.soferman@cloudinary.com","itai.lahan@cloudinary.com","tal.levami@cloudinary.com"]
  s.homepage    = "http://cloudinary.com"
  s.license     = "MIT"

  s.summary     = %q{Client library for easily using the Cloudinary service}
  s.description = %q{Client library for easily using the Cloudinary service}

  s.rubyforge_project = "cloudinary"

  s.files         = `git ls-files`.split("\n").select { |f| !f.start_with?("test", "spec", "features", "samples") } + Dir.glob("vendor/assets/javascripts/*/*") + Dir.glob("vendor/assets/html/*")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "aws_cf_signer"

  if RUBY_VERSION >= "2.0.0"
    s.add_dependency "rest-client", ">= 2.0.0"
  else
    s.add_dependency "rest-client"
  end

  if RUBY_VERSION >= "3.0.0"
    s.add_development_dependency "rexml"
  end

  s.add_development_dependency "actionpack"
  s.add_development_dependency "nokogiri"

  if RUBY_VERSION >= "2.2.0"
    s.add_development_dependency "rake", ">= 13.0.1"
  else
    s.add_development_dependency "rake", "<= 12.2.1"
  end
  if RUBY_VERSION >= "3.0.0"
    s.add_development_dependency "sqlite3"
  else
    s.add_development_dependency "sqlite3", "< 1.6.0"
  end

  s.add_development_dependency "rspec", '>=3.5'
  s.add_development_dependency "rspec-retry"

  if RUBY_VERSION >= "3.0.0"
    s.add_development_dependency "rails", "~> 6.0.3"
  elsif RUBY_VERSION >= "2.2.2"
    s.add_development_dependency "rails", "~> 5.2"
  end

  s.add_development_dependency "railties", "<= 4.2.7" if RUBY_VERSION <= "1.9.3"
  s.add_development_dependency "rspec-rails"

  s.add_development_dependency "rubyzip"

  if RUBY_VERSION <= "2.4.0"
    s.add_development_dependency "simplecov", "<= 0.17.1" # support testing Ruby 1.9
    s.add_development_dependency 'loofah', '~>2.19.1'
    s.add_development_dependency "rails-html-sanitizer", "<1.5.0"
  else
    s.add_development_dependency "simplecov", "> 0.18.0"
  end
end
