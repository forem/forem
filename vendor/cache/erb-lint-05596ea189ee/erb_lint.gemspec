# -*- encoding: utf-8 -*-
# stub: erb_lint 0.0.35 ruby lib

Gem::Specification.new do |s|
  s.name = "erb_lint".freeze
  s.version = "0.0.35"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Justin Chan".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-12-20"
  s.description = "ERB Linter tool.".freeze
  s.email = ["justin.the.c@gmail.com".freeze]
  s.executables = ["erblint".freeze]
  s.files = ["exe/erblint".freeze, "lib/erb_lint.rb".freeze, "lib/erb_lint/cli.rb".freeze, "lib/erb_lint/corrector.rb".freeze, "lib/erb_lint/file_loader.rb".freeze, "lib/erb_lint/linter.rb".freeze, "lib/erb_lint/linter_config.rb".freeze, "lib/erb_lint/linter_registry.rb".freeze, "lib/erb_lint/linters/allowed_script_type.rb".freeze, "lib/erb_lint/linters/closing_erb_tag_indent.rb".freeze, "lib/erb_lint/linters/deprecated_classes.rb".freeze, "lib/erb_lint/linters/erb_safety.rb".freeze, "lib/erb_lint/linters/extra_newline.rb".freeze, "lib/erb_lint/linters/final_newline.rb".freeze, "lib/erb_lint/linters/hard_coded_string.rb".freeze, "lib/erb_lint/linters/no_javascript_tag_helper.rb".freeze, "lib/erb_lint/linters/parser_errors.rb".freeze, "lib/erb_lint/linters/right_trim.rb".freeze, "lib/erb_lint/linters/rubocop.rb".freeze, "lib/erb_lint/linters/rubocop_text.rb".freeze, "lib/erb_lint/linters/self_closing_tag.rb".freeze, "lib/erb_lint/linters/space_around_erb_tag.rb".freeze, "lib/erb_lint/linters/space_in_html_tag.rb".freeze, "lib/erb_lint/linters/space_indentation.rb".freeze, "lib/erb_lint/linters/trailing_whitespace.rb".freeze, "lib/erb_lint/offense.rb".freeze, "lib/erb_lint/processed_source.rb".freeze, "lib/erb_lint/reporter.rb".freeze, "lib/erb_lint/reporters/compact_reporter.rb".freeze, "lib/erb_lint/reporters/multiline_reporter.rb".freeze, "lib/erb_lint/runner.rb".freeze, "lib/erb_lint/runner_config.rb".freeze, "lib/erb_lint/runner_config_resolver.rb".freeze, "lib/erb_lint/stats.rb".freeze, "lib/erb_lint/utils/block_map.rb".freeze, "lib/erb_lint/utils/offset_corrector.rb".freeze, "lib/erb_lint/utils/ruby_to_erb.rb".freeze, "lib/erb_lint/version.rb".freeze]
  s.homepage = "https://github.com/Shopify/erb-lint".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "ERB lint tool".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<better_html>.freeze, ["~> 1.0.7"])
    s.add_runtime_dependency(%q<html_tokenizer>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<parser>.freeze, [">= 2.7.1.4"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<smart_properties>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<rainbow>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-shopify>.freeze, [">= 0"])
  else
    s.add_dependency(%q<better_html>.freeze, ["~> 1.0.7"])
    s.add_dependency(%q<html_tokenizer>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_dependency(%q<parser>.freeze, [">= 2.7.1.4"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<smart_properties>.freeze, [">= 0"])
    s.add_dependency(%q<rainbow>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-shopify>.freeze, [">= 0"])
  end
end
