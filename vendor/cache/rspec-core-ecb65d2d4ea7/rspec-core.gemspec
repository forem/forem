# -*- encoding: utf-8 -*-
# stub: rspec-core 3.11.0.pre ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-core".freeze
  s.version = "3.11.0.pre"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rspec/rspec-core/issues", "changelog_uri" => "https://github.com/rspec/rspec-core/blob/v3.11.0.pre/Changelog.md", "documentation_uri" => "https://rspec.info/documentation/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/rspec", "source_code_uri" => "https://github.com/rspec/rspec-core" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steven Baker".freeze, "David Chelimsky".freeze, "Chad Humphries".freeze, "Myron Marston".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-02-18"
  s.description = "BDD for Ruby. RSpec runner and example groups.".freeze
  s.email = "rspec@googlegroups.com".freeze
  s.executables = ["rspec".freeze]
  s.files = [".document".freeze, ".yardopts".freeze, "Changelog.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "exe/rspec".freeze, "lib/rspec/autorun.rb".freeze, "lib/rspec/core.rb".freeze, "lib/rspec/core/backtrace_formatter.rb".freeze, "lib/rspec/core/bisect/coordinator.rb".freeze, "lib/rspec/core/bisect/example_minimizer.rb".freeze, "lib/rspec/core/bisect/fork_runner.rb".freeze, "lib/rspec/core/bisect/server.rb".freeze, "lib/rspec/core/bisect/shell_command.rb".freeze, "lib/rspec/core/bisect/shell_runner.rb".freeze, "lib/rspec/core/bisect/utilities.rb".freeze, "lib/rspec/core/configuration.rb".freeze, "lib/rspec/core/configuration_options.rb".freeze, "lib/rspec/core/did_you_mean.rb".freeze, "lib/rspec/core/drb.rb".freeze, "lib/rspec/core/dsl.rb".freeze, "lib/rspec/core/example.rb".freeze, "lib/rspec/core/example_group.rb".freeze, "lib/rspec/core/example_status_persister.rb".freeze, "lib/rspec/core/filter_manager.rb".freeze, "lib/rspec/core/flat_map.rb".freeze, "lib/rspec/core/formatters.rb".freeze, "lib/rspec/core/formatters/base_bisect_formatter.rb".freeze, "lib/rspec/core/formatters/base_formatter.rb".freeze, "lib/rspec/core/formatters/base_text_formatter.rb".freeze, "lib/rspec/core/formatters/bisect_drb_formatter.rb".freeze, "lib/rspec/core/formatters/bisect_progress_formatter.rb".freeze, "lib/rspec/core/formatters/console_codes.rb".freeze, "lib/rspec/core/formatters/deprecation_formatter.rb".freeze, "lib/rspec/core/formatters/documentation_formatter.rb".freeze, "lib/rspec/core/formatters/exception_presenter.rb".freeze, "lib/rspec/core/formatters/failure_list_formatter.rb".freeze, "lib/rspec/core/formatters/fallback_message_formatter.rb".freeze, "lib/rspec/core/formatters/helpers.rb".freeze, "lib/rspec/core/formatters/html_formatter.rb".freeze, "lib/rspec/core/formatters/html_printer.rb".freeze, "lib/rspec/core/formatters/html_snippet_extractor.rb".freeze, "lib/rspec/core/formatters/json_formatter.rb".freeze, "lib/rspec/core/formatters/profile_formatter.rb".freeze, "lib/rspec/core/formatters/progress_formatter.rb".freeze, "lib/rspec/core/formatters/protocol.rb".freeze, "lib/rspec/core/formatters/snippet_extractor.rb".freeze, "lib/rspec/core/formatters/syntax_highlighter.rb".freeze, "lib/rspec/core/hooks.rb".freeze, "lib/rspec/core/invocations.rb".freeze, "lib/rspec/core/memoized_helpers.rb".freeze, "lib/rspec/core/metadata.rb".freeze, "lib/rspec/core/metadata_filter.rb".freeze, "lib/rspec/core/minitest_assertions_adapter.rb".freeze, "lib/rspec/core/mocking_adapters/flexmock.rb".freeze, "lib/rspec/core/mocking_adapters/mocha.rb".freeze, "lib/rspec/core/mocking_adapters/null.rb".freeze, "lib/rspec/core/mocking_adapters/rr.rb".freeze, "lib/rspec/core/mocking_adapters/rspec.rb".freeze, "lib/rspec/core/notifications.rb".freeze, "lib/rspec/core/option_parser.rb".freeze, "lib/rspec/core/ordering.rb".freeze, "lib/rspec/core/output_wrapper.rb".freeze, "lib/rspec/core/pending.rb".freeze, "lib/rspec/core/profiler.rb".freeze, "lib/rspec/core/project_initializer.rb".freeze, "lib/rspec/core/project_initializer/.rspec".freeze, "lib/rspec/core/project_initializer/spec/spec_helper.rb".freeze, "lib/rspec/core/rake_task.rb".freeze, "lib/rspec/core/reporter.rb".freeze, "lib/rspec/core/ruby_project.rb".freeze, "lib/rspec/core/runner.rb".freeze, "lib/rspec/core/sandbox.rb".freeze, "lib/rspec/core/set.rb".freeze, "lib/rspec/core/shared_context.rb".freeze, "lib/rspec/core/shared_example_group.rb".freeze, "lib/rspec/core/shell_escape.rb".freeze, "lib/rspec/core/test_unit_assertions_adapter.rb".freeze, "lib/rspec/core/version.rb".freeze, "lib/rspec/core/warnings.rb".freeze, "lib/rspec/core/world.rb".freeze]
  s.homepage = "https://github.com/rspec/rspec-core".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "rspec-core-3.11.0.pre".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_development_dependency(%q<cucumber>.freeze, ["~> 1.3"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3"])
    s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.9"])
    s.add_development_dependency(%q<coderay>.freeze, ["~> 1.1.1"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 0.13.0"])
    s.add_development_dependency(%q<rr>.freeze, ["~> 1.0.4"])
    s.add_development_dependency(%q<flexmock>.freeze, ["~> 0.9.0"])
    s.add_development_dependency(%q<thread_order>.freeze, ["~> 1.1.0"])
  else
    s.add_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<cucumber>.freeze, ["~> 1.3"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.3"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.14.9"])
    s.add_dependency(%q<coderay>.freeze, ["~> 1.1.1"])
    s.add_dependency(%q<mocha>.freeze, ["~> 0.13.0"])
    s.add_dependency(%q<rr>.freeze, ["~> 1.0.4"])
    s.add_dependency(%q<flexmock>.freeze, ["~> 0.9.0"])
    s.add_dependency(%q<thread_order>.freeze, ["~> 1.1.0"])
  end
end
