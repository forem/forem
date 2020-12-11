# -*- encoding: utf-8 -*-
# stub: rspec-rails 4.1.0.pre ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-rails".freeze
  s.version = "4.1.0.pre"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rspec/rspec-rails/issues", "changelog_uri" => "https://github.com/rspec/rspec-rails/blob/v4.1.0.pre/Changelog.md", "documentation_uri" => "https://rspec.info/documentation/", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/rspec", "source_code_uri" => "https://github.com/rspec/rspec-rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Chelimsky".freeze, "Andy Lindeman".freeze]
  s.date = "2021-02-05"
  s.description = "rspec-rails is a testing framework for Rails 5+.".freeze
  s.email = "rspec@googlegroups.com".freeze
  s.files = [".document".freeze, ".yardopts".freeze, "Capybara.md".freeze, "Changelog.md".freeze, "LICENSE.md".freeze, "README.md".freeze, "lib/generators/rspec.rb".freeze, "lib/generators/rspec/channel/channel_generator.rb".freeze, "lib/generators/rspec/channel/templates/channel_spec.rb.erb".freeze, "lib/generators/rspec/controller/controller_generator.rb".freeze, "lib/generators/rspec/controller/templates/controller_spec.rb".freeze, "lib/generators/rspec/controller/templates/request_spec.rb".freeze, "lib/generators/rspec/controller/templates/routing_spec.rb".freeze, "lib/generators/rspec/controller/templates/view_spec.rb".freeze, "lib/generators/rspec/feature/feature_generator.rb".freeze, "lib/generators/rspec/feature/templates/feature_singular_spec.rb".freeze, "lib/generators/rspec/feature/templates/feature_spec.rb".freeze, "lib/generators/rspec/generator/generator_generator.rb".freeze, "lib/generators/rspec/generator/templates/generator_spec.rb".freeze, "lib/generators/rspec/helper/helper_generator.rb".freeze, "lib/generators/rspec/helper/templates/helper_spec.rb".freeze, "lib/generators/rspec/install/install_generator.rb".freeze, "lib/generators/rspec/install/templates/spec/rails_helper.rb".freeze, "lib/generators/rspec/integration/integration_generator.rb".freeze, "lib/generators/rspec/integration/templates/request_spec.rb".freeze, "lib/generators/rspec/job/job_generator.rb".freeze, "lib/generators/rspec/job/templates/job_spec.rb.erb".freeze, "lib/generators/rspec/mailbox/mailbox_generator.rb".freeze, "lib/generators/rspec/mailbox/templates/mailbox_spec.rb.erb".freeze, "lib/generators/rspec/mailer/mailer_generator.rb".freeze, "lib/generators/rspec/mailer/templates/fixture".freeze, "lib/generators/rspec/mailer/templates/mailer_spec.rb".freeze, "lib/generators/rspec/mailer/templates/preview.rb".freeze, "lib/generators/rspec/model/model_generator.rb".freeze, "lib/generators/rspec/model/templates/fixtures.yml".freeze, "lib/generators/rspec/model/templates/model_spec.rb".freeze, "lib/generators/rspec/request/request_generator.rb".freeze, "lib/generators/rspec/scaffold/scaffold_generator.rb".freeze, "lib/generators/rspec/scaffold/templates/api_controller_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/api_request_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/controller_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/edit_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/index_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/new_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/request_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/routing_spec.rb".freeze, "lib/generators/rspec/scaffold/templates/show_spec.rb".freeze, "lib/generators/rspec/system/system_generator.rb".freeze, "lib/generators/rspec/system/templates/system_spec.rb".freeze, "lib/generators/rspec/view/templates/view_spec.rb".freeze, "lib/generators/rspec/view/view_generator.rb".freeze, "lib/rspec-rails.rb".freeze, "lib/rspec/rails.rb".freeze, "lib/rspec/rails/active_record.rb".freeze, "lib/rspec/rails/adapters.rb".freeze, "lib/rspec/rails/configuration.rb".freeze, "lib/rspec/rails/example.rb".freeze, "lib/rspec/rails/example/channel_example_group.rb".freeze, "lib/rspec/rails/example/controller_example_group.rb".freeze, "lib/rspec/rails/example/feature_example_group.rb".freeze, "lib/rspec/rails/example/helper_example_group.rb".freeze, "lib/rspec/rails/example/job_example_group.rb".freeze, "lib/rspec/rails/example/mailbox_example_group.rb".freeze, "lib/rspec/rails/example/mailer_example_group.rb".freeze, "lib/rspec/rails/example/model_example_group.rb".freeze, "lib/rspec/rails/example/rails_example_group.rb".freeze, "lib/rspec/rails/example/request_example_group.rb".freeze, "lib/rspec/rails/example/routing_example_group.rb".freeze, "lib/rspec/rails/example/system_example_group.rb".freeze, "lib/rspec/rails/example/view_example_group.rb".freeze, "lib/rspec/rails/extensions.rb".freeze, "lib/rspec/rails/extensions/active_record/proxy.rb".freeze, "lib/rspec/rails/feature_check.rb".freeze, "lib/rspec/rails/file_fixture_support.rb".freeze, "lib/rspec/rails/fixture_file_upload_support.rb".freeze, "lib/rspec/rails/fixture_support.rb".freeze, "lib/rspec/rails/matchers.rb".freeze, "lib/rspec/rails/matchers/action_cable.rb".freeze, "lib/rspec/rails/matchers/action_cable/have_broadcasted_to.rb".freeze, "lib/rspec/rails/matchers/action_cable/have_streams.rb".freeze, "lib/rspec/rails/matchers/action_mailbox.rb".freeze, "lib/rspec/rails/matchers/active_job.rb".freeze, "lib/rspec/rails/matchers/base_matcher.rb".freeze, "lib/rspec/rails/matchers/be_a_new.rb".freeze, "lib/rspec/rails/matchers/be_new_record.rb".freeze, "lib/rspec/rails/matchers/be_valid.rb".freeze, "lib/rspec/rails/matchers/have_enqueued_mail.rb".freeze, "lib/rspec/rails/matchers/have_http_status.rb".freeze, "lib/rspec/rails/matchers/have_rendered.rb".freeze, "lib/rspec/rails/matchers/redirect_to.rb".freeze, "lib/rspec/rails/matchers/relation_match_array.rb".freeze, "lib/rspec/rails/matchers/routing_matchers.rb".freeze, "lib/rspec/rails/tasks/rspec.rake".freeze, "lib/rspec/rails/vendor/capybara.rb".freeze, "lib/rspec/rails/version.rb".freeze, "lib/rspec/rails/view_assigns.rb".freeze, "lib/rspec/rails/view_path_builder.rb".freeze, "lib/rspec/rails/view_rendering.rb".freeze, "lib/rspec/rails/view_spec_methods.rb".freeze]
  s.homepage = "https://github.com/rspec/rspec-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.1.4".freeze
  s.summary = "RSpec for Rails".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 4.2"])
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2"])
    s.add_runtime_dependency(%q<railties>.freeze, [">= 4.2"])
    s.add_runtime_dependency(%q<rspec-core>.freeze, ["= 3.11.0.pre"])
    s.add_runtime_dependency(%q<rspec-expectations>.freeze, ["= 3.11.0.pre"])
    s.add_runtime_dependency(%q<rspec-mocks>.freeze, ["= 3.11.0.pre"])
    s.add_runtime_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_development_dependency(%q<ammeter>.freeze, ["~> 1.1.2"])
    s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.12"])
    s.add_development_dependency(%q<cucumber>.freeze, ["~> 1.3.5"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 4.2"])
    s.add_dependency(%q<activesupport>.freeze, [">= 4.2"])
    s.add_dependency(%q<railties>.freeze, [">= 4.2"])
    s.add_dependency(%q<rspec-core>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<rspec-expectations>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<rspec-mocks>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<rspec-support>.freeze, ["= 3.11.0.pre"])
    s.add_dependency(%q<ammeter>.freeze, ["~> 1.1.2"])
    s.add_dependency(%q<aruba>.freeze, ["~> 0.14.12"])
    s.add_dependency(%q<cucumber>.freeze, ["~> 1.3.5"])
  end
end
