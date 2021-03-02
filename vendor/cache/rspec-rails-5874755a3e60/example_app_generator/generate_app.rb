require 'nokogiri'

rspec_rails_repo_path = File.expand_path('..', __dir__)
rspec_dependencies_gemfile = File.join(rspec_rails_repo_path, 'Gemfile-rspec-dependencies')
rails_dependencies_gemfile = File.join(rspec_rails_repo_path, 'Gemfile-rails-dependencies')
bundle_install_path = File.join(rspec_rails_repo_path, '..', 'bundle')
maintenance_branch_file = File.join(rspec_rails_repo_path, 'maintenance-branch')
travis_retry_script = File.join(
  rspec_rails_repo_path,
  'example_app_generator',
  'travis_retry_bundle_install.sh'
)
function_script_file = File.join(rspec_rails_repo_path, 'script/functions.sh')
sqlite_initializer = File.join(rspec_rails_repo_path, "example_app_generator/config/initializers/sqlite3_fix.rb")

in_root do
  prepend_to_file "Rakefile", "require 'active_support/all'"

  # Remove the existing rails version so we can properly use main or other
  # edge branches
  gsub_file 'Gemfile', /^.*\bgem 'rails.*$/, ''
  gsub_file "Gemfile", /.*web-console.*/, ''
  gsub_file "Gemfile", /.*debugger.*/, ''
  gsub_file "Gemfile", /.*puma.*/, ''
  gsub_file "Gemfile", /.*bootsnap.*/, ''

  # We soft-support Rails 4.2. `rails-controller-testing` only supports Rails 5+.
  # This conditional is to facilitate local testing against Rails 4.2.
  if Rails::VERSION::STRING >= '5'
    append_to_file 'Gemfile', "gem 'rails-controller-testing'\n"
  end

  if Rails::VERSION::STRING >= '6'
    gsub_file "Gemfile", /.*rails-controller-testing.*/, "gem 'rails-controller-testing', git: 'https://github.com/rails/rails-controller-testing'"

    # TODO: To remove when Rails released with https://github.com/rails/rails/pull/40281
    append_to_file 'Gemfile', <<-EOT.gsub(/^ +\|/, '')
      |gem 'rexml'
    EOT
  end

  if Rails::VERSION::STRING >= '6'
    # sqlite3 is an optional, unspecified, dependency and Rails 6.0 only supports `~> 1.4`
    gsub_file "Gemfile", /.*gem..sqlite3.*/, "gem 'sqlite3', '~> 1.4'"
  else
    # Similarly, Rails 5.0 only supports '~> 1.3.6'. Rails 5.1-5.2 support '~> 1.3', '>= 1.3.6'
    gsub_file "Gemfile", /.*gem..sqlite3.*/, "gem 'sqlite3', '~> 1.3.6'"
  end

  if Rails::VERSION::STRING >= "5.1.0"
    # webdrivers 4 up until 4.3.0 don't specify `required_ruby_version`, but contain
    # Ruby 2.2-incompatible syntax (safe navigation).
    # That basically means we use pre-4.0 for Ruby 2.2, and 4.3+ for newer Rubies.
    gsub_file "Gemfile", /.*chromedriver-helper.*/, "gem 'webdrivers', '!= 4.0.0', '!= 4.0.1', '!= 4.1.0', '!= 4.1.1', '!= 4.1.2', '!= 4.1.3', '!= 4.2.0'"
  end

  if Rails::VERSION::STRING >= '5.2.0' && Rails::VERSION::STRING < '6'
    copy_file sqlite_initializer, 'config/initializers/sqlite3_fix.rb'
  end

  if RUBY_ENGINE == "jruby"
    gsub_file "Gemfile", /.*jdbc.*/, ''
  end

  # Use our version of RSpec and Rails
  append_to_file 'Gemfile', <<-EOT.gsub(/^ +\|/, '')
    |gem 'rake', '>= 10.0.0'
    |
    |gem 'rspec-rails',
    |    :path => '#{rspec_rails_repo_path}',
    |    :groups => [:development, :test]
    |eval_gemfile '#{rspec_dependencies_gemfile}'
    |eval_gemfile '#{rails_dependencies_gemfile}'
  EOT

  copy_file maintenance_branch_file, 'maintenance-branch'

  copy_file travis_retry_script, 'travis_retry_bundle_install.sh'
  gsub_file 'travis_retry_bundle_install.sh',
            'FUNCTIONS_SCRIPT_FILE',
            function_script_file
  gsub_file 'travis_retry_bundle_install.sh',
            'REPLACE_BUNDLE_PATH',
            bundle_install_path
  chmod 'travis_retry_bundle_install.sh', 0755
end
