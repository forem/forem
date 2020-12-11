# -*- encoding: utf-8 -*-
# stub: rspec-support 3.11.0.pre ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-support".freeze
  s.version = "3.11.0.pre"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rspec/rspec-support/issues", "changelog_uri" => "https://github.com/rspec/rspec-support/blob/v3.11.0.pre/Changelog.md", "documentation_uri" => "https://rspec.info/documentation/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/rspec", "source_code_uri" => "https://github.com/rspec/rspec-support" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Chelimsky".freeze, "Myron Marson".freeze, "Jon Rowe".freeze, "Sam Phippen".freeze, "Xaviery Shay".freeze, "Bradley Schaefer".freeze]
  s.date = "2021-02-05"
  s.description = "Support utilities for RSpec gems".freeze
  s.email = "rspec-users@rubyforge.org".freeze
  s.files = ["Changelog.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "lib/rspec/support.rb".freeze, "lib/rspec/support/caller_filter.rb".freeze, "lib/rspec/support/comparable_version.rb".freeze, "lib/rspec/support/differ.rb".freeze, "lib/rspec/support/directory_maker.rb".freeze, "lib/rspec/support/encoded_string.rb".freeze, "lib/rspec/support/fuzzy_matcher.rb".freeze, "lib/rspec/support/hunk_generator.rb".freeze, "lib/rspec/support/matcher_definition.rb".freeze, "lib/rspec/support/method_signature_verifier.rb".freeze, "lib/rspec/support/mutex.rb".freeze, "lib/rspec/support/object_formatter.rb".freeze, "lib/rspec/support/recursive_const_methods.rb".freeze, "lib/rspec/support/reentrant_mutex.rb".freeze, "lib/rspec/support/ruby_features.rb".freeze, "lib/rspec/support/source.rb".freeze, "lib/rspec/support/source/location.rb".freeze, "lib/rspec/support/source/node.rb".freeze, "lib/rspec/support/source/token.rb".freeze, "lib/rspec/support/spec.rb".freeze, "lib/rspec/support/spec/deprecation_helpers.rb".freeze, "lib/rspec/support/spec/diff_helpers.rb".freeze, "lib/rspec/support/spec/formatting_support.rb".freeze, "lib/rspec/support/spec/in_sub_process.rb".freeze, "lib/rspec/support/spec/library_wide_checks.rb".freeze, "lib/rspec/support/spec/shell_out.rb".freeze, "lib/rspec/support/spec/stderr_splitter.rb".freeze, "lib/rspec/support/spec/string_matcher.rb".freeze, "lib/rspec/support/spec/with_isolated_directory.rb".freeze, "lib/rspec/support/spec/with_isolated_stderr.rb".freeze, "lib/rspec/support/version.rb".freeze, "lib/rspec/support/warnings.rb".freeze, "lib/rspec/support/with_keywords_when_needed.rb".freeze]
  s.homepage = "https://github.com/rspec/rspec-support".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "rspec-support-3.11.0.pre".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["> 10.0.0"])
    s.add_development_dependency(%q<thread_order>.freeze, ["~> 1.1.0"])
  else
    s.add_dependency(%q<rake>.freeze, ["> 10.0.0"])
    s.add_dependency(%q<thread_order>.freeze, ["~> 1.1.0"])
  end
end
