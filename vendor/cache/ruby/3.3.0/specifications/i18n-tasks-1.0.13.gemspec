# -*- encoding: utf-8 -*-
# stub: i18n-tasks 1.0.13 ruby lib

Gem::Specification.new do |s|
  s.name = "i18n-tasks".freeze
  s.version = "1.0.13".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "issue_tracker" => "https://github.com/glebm/i18n-tasks", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["glebm".freeze]
  s.date = "2023-10-14"
  s.description = "i18n-tasks helps you find and manage missing and unused translations.\n\nIt analyses code statically for key usages, such as `I18n.t('some.key')`, in order to report keys that are missing or unused,\npre-fill missing keys (optionally from Google Translate), and remove unused keys.\n".freeze
  s.email = ["glex.spb@gmail.com".freeze]
  s.executables = ["i18n-tasks".freeze]
  s.files = ["bin/i18n-tasks".freeze]
  s.homepage = "https://github.com/glebm/i18n-tasks".freeze
  s.licenses = ["MIT".freeze]
  s.post_install_message = "# Install default configuration:\ncp $(bundle exec i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/\n# Add an RSpec for missing and unused keys:\ncp $(bundle exec i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/\n# Or for minitest:\ncp $(bundle exec i18n-tasks gem-path)/templates/minitest/i18n_test.rb test/\n".freeze
  s.required_ruby_version = Gem::Requirement.new([">= 2.6".freeze, "< 4.0".freeze])
  s.rubygems_version = "3.5.3".freeze
  s.summary = "Manage localization and translation with the awesome power of static analysis".freeze

  s.installed_by_version = "3.5.3".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.0.2".freeze])
  s.add_runtime_dependency(%q<ast>.freeze, [">= 2.1.0".freeze])
  s.add_runtime_dependency(%q<better_html>.freeze, [">= 1.0".freeze, "< 3.0".freeze])
  s.add_runtime_dependency(%q<erubi>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<highline>.freeze, [">= 2.0.0".freeze])
  s.add_runtime_dependency(%q<i18n>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<parser>.freeze, [">= 3.2.2.1".freeze])
  s.add_runtime_dependency(%q<rails-i18n>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2.2".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 1.5.1".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze, ">= 2.0.1".freeze])
  s.add_development_dependency(%q<overcommit>.freeze, ["~> 0.58.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.3".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.50.1".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.6.0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 2.19.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<deepl-rb>.freeze, [">= 2.1.0".freeze])
  s.add_development_dependency(%q<easy_translate>.freeze, [">= 0.5.1".freeze])
  s.add_development_dependency(%q<yandex-translator>.freeze, [">= 0.3.3".freeze])
end
