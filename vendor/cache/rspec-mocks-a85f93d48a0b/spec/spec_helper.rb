require 'rspec/support/spec'
require 'rspec/support/ruby_features'

RSpec::Support::Spec.setup_simplecov do
  minimum_coverage 93
end

require 'yaml'
begin
  require 'psych'
rescue LoadError
end

RSpec::Matchers.define :include_method do |expected|
  match do |actual|
    actual.map { |m| m.to_s }.include?(expected.to_s)
  end
end
require 'support/matchers'

module VerifyAndResetHelpers
  def verify(object)
    proxy = RSpec::Mocks.space.proxy_for(object)
    proxy.verify
  ensure
    proxy.reset # so it doesn't fail the verify after the example completes
  end

  def reset(object)
    RSpec::Mocks.space.proxy_for(object).reset
  end

  def verify_all
    RSpec::Mocks.space.verify_all
  ensure
    reset_all
  end

  def reset_all
    RSpec::Mocks.space.reset_all
  end

  def with_unfulfilled_double
    d = double("double")
    yield d
  ensure
    reset d
  end

  def expect_fast_failure_from(double, *fail_with_args, &blk)
    expect { blk.call(double) }.to fail_with(*fail_with_args)
    reset double
  end
end

module VerificationHelpers
  def prevents(msg=//, &block)
    expect(&block).to fail_with msg
  end
end

module MatcherHelpers
  def self.fake_matcher_description
    "fake_matcher_description"
  end

  extend RSpec::Matchers::DSL

  matcher :fake_matcher do |expected|
    match { |actual| actual == expected }

    description do
      MatcherHelpers.fake_matcher_description
    end
  end
end

require 'rspec/support/spec'

RSpec.configure do |config|
  config.expose_dsl_globally = false
  config.mock_with :rspec
  config.color = true
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    $default_rspec_mocks_syntax = mocks.syntax
    mocks.syntax = :expect
  end

  old_verbose = nil
  config.before(:each, :silence_warnings) do
    old_verbose = $VERBOSE
    $VERBOSE = nil
  end

  config.after(:each, :silence_warnings) do
    $VERBOSE = old_verbose
  end

  config.include VerifyAndResetHelpers
  config.include MatcherHelpers
  config.include VerificationHelpers
  config.extend RSpec::Support::RubyFeatures
  config.include RSpec::Support::RubyFeatures

  config.define_derived_metadata :ordered_and_vague_counts_unsupported do |meta|
    meta[:pending] = "`.ordered` combined with a vague count (e.g. `at_least` or `at_most`) is not yet supported (see #713)"
  end

  # We have yet to try to address this issue, and it's just noise in our output,
  # so skip it locally. However, on CI we want it to still run them so that if
  # we do something that makes these specs pass, we are notified.
  config.filter_run_excluding :ordered_and_vague_counts_unsupported unless ENV['CI']

  # We don't want rspec-core to look in our `lib` for failure snippets.
  # When it does that, it inevitably finds this line:
  # `RSpec::Support.notify_failure(*args)`
  # ...which isn't very helpful. Far better for it to find the expectation
  # call site in the spec.
  config.project_source_dirs -= %w[ lib ]

  RSpec::Matchers.define_negated_matcher :a_string_excluding, :include
end

RSpec.shared_context "with syntax" do |syntax|
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.syntax = syntax
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end
end

RSpec.shared_context "with isolated configuration" do
  orig_configuration = nil
  before do
    orig_configuration = RSpec::Mocks.configuration
    RSpec::Mocks.instance_variable_set(:@configuration, RSpec::Mocks::Configuration.new)
  end

  after do
    RSpec::Mocks.instance_variable_set(:@configuration, orig_configuration)
  end
end

RSpec.shared_context "with monkey-patched marshal" do
  before do
    RSpec::Mocks.configuration.patch_marshal_to_support_partial_doubles = true
  end

  after do
    RSpec::Mocks.configuration.patch_marshal_to_support_partial_doubles = false
  end
end

RSpec.shared_context "with the default mocks syntax" do
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Mocks.configuration.syntax
    RSpec::Mocks.configuration.reset_syntaxes_to_default
  end

  after(:all) do
    RSpec::Mocks.configuration.syntax = orig_syntax
  end
end
