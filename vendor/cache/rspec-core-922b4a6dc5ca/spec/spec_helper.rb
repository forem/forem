require 'rubygems' if RUBY_VERSION.to_f < 1.9

require 'rspec/support/spec'

$rspec_core_without_stderr_monkey_patch = RSpec::Core::Configuration.new

class RSpec::Core::Configuration
  def self.new(*args, &block)
    super.tap do |config|
      # We detect ruby warnings via $stderr,
      # so direct our deprecations to $stdout instead.
      config.deprecation_stream = $stdout
    end
  end
end

Dir['./spec/support/**/*.rb'].map do |file|
  # fake libs aren't intended to be loaded except by some specific specs
  # that shell out and run a new process.
  next if file =~ /fake_libs/

  # Ensure requires are relative to `spec`, which is on the
  # load path. This helps prevent double requires on 1.8.7.
  require file.gsub("./spec/support", "support")
end

class RaiseOnFailuresReporter < RSpec::Core::NullReporter
  def self.example_failed(example)
    raise example.exception
  end
end

module CommonHelpers
  def describe_successfully(*args, &describe_body)
    example_group    = RSpec.describe(*args, &describe_body)
    ran_successfully = example_group.run RaiseOnFailuresReporter
    expect(ran_successfully).to eq true
    example_group
  end

  def with_env_vars(vars)
    original = ENV.to_hash
    vars.each { |k, v| ENV[k] = v }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end

  def without_env_vars(*vars)
    original = ENV.to_hash
    vars.each { |k| ENV.delete(k) }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end

  def handle_current_dir_change
    RSpec::Core::Metadata.instance_variable_set(:@relative_path_regex, nil)
    yield
  ensure
    RSpec::Core::Metadata.instance_variable_set(:@relative_path_regex, nil)
  end
end

RSpec.configure do |c|
  c.example_status_persistence_file_path = "./spec/examples.txt"
  c.around(:example, :isolated_directory) do |ex|
    handle_current_dir_change(&ex)
  end

  # structural
  c.alias_it_behaves_like_to 'it_has_behavior'
  c.include(RSpecHelpers)
  c.disable_monkey_patching!

  # runtime options
  c.raise_errors_for_deprecations!
  c.color = true
  c.include CommonHelpers

  c.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = 1000
  end

  c.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  c.around(:example, :simulate_shell_allowing_unquoted_ids) do |ex|
    with_env_vars('SHELL' => '/usr/local/bin/bash', &ex)
  end

  if ENV['CI'] && RSpec::Support::OS.windows? && RUBY_VERSION.to_f < 2.3
    c.around(:example, :emits_warning_on_windows_on_old_ruby) do |ex|
      ignoring_warnings(&ex)
    end

    c.define_derived_metadata(:pending_on_windows_old_ruby => true) do |metadata|
      metadata[:pending] = "This example is expected to fail on windows, on ruby older than 2.3"
    end
  end

  c.filter_run_excluding :ruby => lambda {|version|
    case version.to_s
    when "!jruby"
      RUBY_ENGINE == "jruby"
    when /^> (.*)/
      !(RUBY_VERSION.to_s > $1)
    else
      !(RUBY_VERSION.to_s =~ /^#{version.to_s}/)
    end
  }

  $original_rspec_configuration = c
end
