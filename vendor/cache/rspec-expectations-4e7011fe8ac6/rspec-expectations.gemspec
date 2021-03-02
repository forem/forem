# -*- encoding: utf-8 -*-
# stub: rspec-expectations 3.11.0.pre ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-expectations".freeze
  s.version = "3.11.0.pre"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rspec/rspec-expectations/issues", "changelog_uri" => "https://github.com/rspec/rspec-expectations/blob/v3.11.0.pre/Changelog.md", "documentation_uri" => "https://rspec.info/documentation/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/rspec", "source_code_uri" => "https://github.com/rspec/rspec-expectations" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Baker".freeze, "David Chelimsky".freeze, "Myron Marston".freeze]
  s.date = "2021-03-02"
  s.description = "rspec-expectations provides a simple, readable API to express expected outcomes of a code example.".freeze
  s.email = "rspec@googlegroups.com".freeze
  s.files = [".document".freeze, ".yardopts".freeze, "Changelog.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "lib/rspec/expectations.rb".freeze, "lib/rspec/expectations/block_snippet_extractor.rb".freeze, "lib/rspec/expectations/configuration.rb".freeze, "lib/rspec/expectations/expectation_target.rb".freeze, "lib/rspec/expectations/fail_with.rb".freeze, "lib/rspec/expectations/failure_aggregator.rb".freeze, "lib/rspec/expectations/handler.rb".freeze, "lib/rspec/expectations/minitest_integration.rb".freeze, "lib/rspec/expectations/syntax.rb".freeze, "lib/rspec/expectations/version.rb".freeze, "lib/rspec/matchers.rb".freeze, "lib/rspec/matchers/aliased_matcher.rb".freeze, "lib/rspec/matchers/built_in.rb".freeze, "lib/rspec/matchers/built_in/all.rb".freeze, "lib/rspec/matchers/built_in/base_matcher.rb".freeze, "lib/rspec/matchers/built_in/be.rb".freeze, "lib/rspec/matchers/built_in/be_between.rb".freeze, "lib/rspec/matchers/built_in/be_instance_of.rb".freeze, "lib/rspec/matchers/built_in/be_kind_of.rb".freeze, "lib/rspec/matchers/built_in/be_within.rb".freeze, "lib/rspec/matchers/built_in/change.rb".freeze, "lib/rspec/matchers/built_in/compound.rb".freeze, "lib/rspec/matchers/built_in/contain_exactly.rb".freeze, "lib/rspec/matchers/built_in/count_expectation.rb".freeze, "lib/rspec/matchers/built_in/cover.rb".freeze, "lib/rspec/matchers/built_in/eq.rb".freeze, "lib/rspec/matchers/built_in/eql.rb".freeze, "lib/rspec/matchers/built_in/equal.rb".freeze, "lib/rspec/matchers/built_in/exist.rb".freeze, "lib/rspec/matchers/built_in/has.rb".freeze, "lib/rspec/matchers/built_in/have_attributes.rb".freeze, "lib/rspec/matchers/built_in/include.rb".freeze, "lib/rspec/matchers/built_in/match.rb".freeze, "lib/rspec/matchers/built_in/operators.rb".freeze, "lib/rspec/matchers/built_in/output.rb".freeze, "lib/rspec/matchers/built_in/raise_error.rb".freeze, "lib/rspec/matchers/built_in/respond_to.rb".freeze, "lib/rspec/matchers/built_in/satisfy.rb".freeze, "lib/rspec/matchers/built_in/start_or_end_with.rb".freeze, "lib/rspec/matchers/built_in/throw_symbol.rb".freeze, "lib/rspec/matchers/built_in/yield.rb".freeze, "lib/rspec/matchers/composable.rb".freeze, "lib/rspec/matchers/dsl.rb".freeze, "lib/rspec/matchers/english_phrasing.rb".freeze, "lib/rspec/matchers/expecteds_for_multiple_diffs.rb".freeze, "lib/rspec/matchers/fail_matchers.rb".freeze, "lib/rspec/matchers/generated_descriptions.rb".freeze, "lib/rspec/matchers/matcher_delegator.rb".freeze, "lib/rspec/matchers/matcher_protocol.rb".freeze]
  s.homepage = "https://github.com/rspec/rspec-expectations".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "rspec-expectations-3.11.0.pre".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_runtime_dependency(%q<diff-lcs>.freeze, [">= 1.2.0", "< 2.0"])
    s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.10"])
    s.add_development_dependency(%q<cucumber>.freeze, ["~> 1.3"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.2"])
    s.add_development_dependency(%q<rake>.freeze, ["> 10.0.0"])
  else
    s.add_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<diff-lcs>.freeze, [">= 1.2.0", "< 2.0"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.14.10"])
    s.add_dependency(%q<cucumber>.freeze, ["~> 1.3"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.2"])
    s.add_dependency(%q<rake>.freeze, ["> 10.0.0"])
  end
end
