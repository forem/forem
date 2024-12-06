# -*- encoding: utf-8 -*-
# stub: cloudinary 1.29.0 ruby lib

Gem::Specification.new do |s|
  s.name = "cloudinary".freeze
  s.version = "1.29.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nadav Soferman".freeze, "Itai Lahan".freeze, "Tal Lev-Ami".freeze]
  s.date = "2024-02-26"
  s.description = "Client library for easily using the Cloudinary service".freeze
  s.email = ["nadav.soferman@cloudinary.com".freeze, "itai.lahan@cloudinary.com".freeze, "tal.levami@cloudinary.com".freeze]
  s.homepage = "http://cloudinary.com".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Client library for easily using the Cloudinary service".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws_cf_signer>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rest-client>.freeze, [">= 2.0.0".freeze])
  s.add_development_dependency(%q<actionpack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<nokogiri>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 13.0.1".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["< 1.6.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.5".freeze])
  s.add_development_dependency(%q<rspec-retry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, ["~> 5.2".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubyzip>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["> 0.18.0".freeze])
end
