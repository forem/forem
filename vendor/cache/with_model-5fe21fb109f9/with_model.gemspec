# -*- encoding: utf-8 -*-
# stub: with_model 2.1.6 ruby lib

Gem::Specification.new do |s|
  s.name = "with_model".freeze
  s.version = "2.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Case Commons, LLC".freeze, "Grant Hutchins".freeze, "Andrew Marshall".freeze]
  s.date = "2023-08-18"
  s.description = "Dynamically build a model within an RSpec context".freeze
  s.email = ["casecommons-dev@googlegroups.com".freeze, "gems@nertzy.com".freeze, "andrew@johnandrewmarshall.com".freeze]
  s.files = [".bundle/config".freeze, ".github/dependabot.yml".freeze, ".github/workflows/ci.yml".freeze, ".gitignore".freeze, ".jrubyrc".freeze, ".rspec".freeze, ".rubocop.yml".freeze, ".rubocop_todo.yml".freeze, ".yardopts".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "lib/with_model.rb".freeze, "lib/with_model/constant_stubber.rb".freeze, "lib/with_model/methods.rb".freeze, "lib/with_model/model.rb".freeze, "lib/with_model/model/dsl.rb".freeze, "lib/with_model/table.rb".freeze, "lib/with_model/version.rb".freeze, "spec/.rubocop.yml".freeze, "spec/active_record_behaviors_spec.rb".freeze, "spec/constant_stubber_spec.rb".freeze, "spec/readme_spec.rb".freeze, "spec/spec_helper.rb".freeze, "spec/with_model_spec.rb".freeze, "test/test_helper.rb".freeze, "test/with_model_test.rb".freeze, "with_model.gemspec".freeze]
  s.homepage = "https://github.com/Casecommons/with_model".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.26".freeze
  s.summary = "Dynamically build a model within an RSpec context".freeze

  s.installed_by_version = "3.3.26" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.0"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 6.0"])
  end
end
