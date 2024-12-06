# -*- encoding: utf-8 -*-
# stub: aws_cf_signer 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "aws_cf_signer".freeze
  s.version = "0.1.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dylan Vaughn".freeze]
  s.date = "2014-05-26"
  s.email = ["dylancvaughn@gmail.com".freeze]
  s.homepage = "https://github.com/dylanvaughn/aws_cf_signer".freeze
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Ruby gem for signing AWS Cloudfront URLs for serving private content.".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, ["~> 10.1".freeze])
  s.add_development_dependency(%q<thoughtbot-shoulda>.freeze, ["~> 2.11".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.8".freeze])
end
