# -*- encoding: utf-8 -*-
# stub: rspec-mocks 3.11.0.pre ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-mocks".freeze
  s.version = "3.11.0.pre"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rspec/rspec-mocks/issues", "changelog_uri" => "https://github.com/rspec/rspec-mocks/blob/v3.11.0.pre/Changelog.md", "documentation_uri" => "https://rspec.info/documentation/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/rspec", "source_code_uri" => "https://github.com/rspec/rspec-mocks" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Baker".freeze, "David Chelimsky".freeze, "Myron Marston".freeze]
  s.date = "2021-02-05"
  s.description = "RSpec's 'test double' framework, with support for stubbing and mocking".freeze
  s.email = "rspec@googlegroups.com".freeze
  s.files = [".document".freeze, ".yardopts".freeze, "Changelog.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "lib/rspec/mocks.rb".freeze, "lib/rspec/mocks/any_instance.rb".freeze, "lib/rspec/mocks/any_instance/chain.rb".freeze, "lib/rspec/mocks/any_instance/error_generator.rb".freeze, "lib/rspec/mocks/any_instance/expect_chain_chain.rb".freeze, "lib/rspec/mocks/any_instance/expectation_chain.rb".freeze, "lib/rspec/mocks/any_instance/message_chains.rb".freeze, "lib/rspec/mocks/any_instance/proxy.rb".freeze, "lib/rspec/mocks/any_instance/recorder.rb".freeze, "lib/rspec/mocks/any_instance/stub_chain.rb".freeze, "lib/rspec/mocks/any_instance/stub_chain_chain.rb".freeze, "lib/rspec/mocks/argument_list_matcher.rb".freeze, "lib/rspec/mocks/argument_matchers.rb".freeze, "lib/rspec/mocks/configuration.rb".freeze, "lib/rspec/mocks/error_generator.rb".freeze, "lib/rspec/mocks/example_methods.rb".freeze, "lib/rspec/mocks/instance_method_stasher.rb".freeze, "lib/rspec/mocks/marshal_extension.rb".freeze, "lib/rspec/mocks/matchers/expectation_customization.rb".freeze, "lib/rspec/mocks/matchers/have_received.rb".freeze, "lib/rspec/mocks/matchers/receive.rb".freeze, "lib/rspec/mocks/matchers/receive_message_chain.rb".freeze, "lib/rspec/mocks/matchers/receive_messages.rb".freeze, "lib/rspec/mocks/message_chain.rb".freeze, "lib/rspec/mocks/message_expectation.rb".freeze, "lib/rspec/mocks/method_double.rb".freeze, "lib/rspec/mocks/method_reference.rb".freeze, "lib/rspec/mocks/minitest_integration.rb".freeze, "lib/rspec/mocks/mutate_const.rb".freeze, "lib/rspec/mocks/object_reference.rb".freeze, "lib/rspec/mocks/order_group.rb".freeze, "lib/rspec/mocks/proxy.rb".freeze, "lib/rspec/mocks/space.rb".freeze, "lib/rspec/mocks/standalone.rb".freeze, "lib/rspec/mocks/syntax.rb".freeze, "lib/rspec/mocks/targets.rb".freeze, "lib/rspec/mocks/test_double.rb".freeze, "lib/rspec/mocks/verifying_double.rb".freeze, "lib/rspec/mocks/verifying_message_expectation.rb".freeze, "lib/rspec/mocks/verifying_proxy.rb".freeze, "lib/rspec/mocks/version.rb".freeze]
  s.homepage = "https://github.com/rspec/rspec-mocks".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "rspec-mocks-3.11.0.pre".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_runtime_dependency(%q<diff-lcs>.freeze, [">= 1.2.0", "< 2.0"])
    s.add_development_dependency(%q<rake>.freeze, ["> 10.0.0"])
    s.add_development_dependency(%q<cucumber>.freeze, ["~> 1.3.15"])
    s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.10"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.2"])
  else
    s.add_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<diff-lcs>.freeze, [">= 1.2.0", "< 2.0"])
    s.add_dependency(%q<rake>.freeze, ["> 10.0.0"])
    s.add_dependency(%q<cucumber>.freeze, ["~> 1.3.15"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.14.10"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.2"])
  end
end
