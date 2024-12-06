# -*- encoding: utf-8 -*-
# stub: vault 0.18.2 ruby lib

Gem::Specification.new do |s|
  s.name = "vault".freeze
  s.version = "0.18.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Seth Vargo".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-11-27"
  s.description = "Vault is a Ruby API client for interacting with a Vault server.".freeze
  s.email = ["team-vault-devex@hashicorp.com".freeze]
  s.homepage = "https://github.com/hashicorp/vault-ruby".freeze
  s.licenses = ["MPL-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Vault is a Ruby API client for interacting with a Vault server.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<aws-sigv4>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.13.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.24".freeze])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.8.3".freeze])
  s.add_development_dependency(%q<webrick>.freeze, ["~> 1.5".freeze])
end
