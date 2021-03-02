require 'rspec/support/spec'
require 'rspec/support/spec/in_sub_process'

RSpec::Support::Spec.setup_simplecov do
  minimum_coverage 92
end

Dir['./spec/support/**/*.rb'].each do |f|
  require f.sub(%r{\./spec/}, '')
end

module CommonHelperMethods
  def with_env_vars(vars)
    original = ENV.to_hash
    vars.each { |k, v| ENV[k] = v }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end

  def dedent(string)
    string.gsub(/^\s+\|/, '').chomp
  end

  # We have to use Hash#inspect in examples that have multi-entry
  # hashes because the #inspect output on 1.8.7 is non-deterministic
  # due to the fact that hashes are not ordered. So we can't simply
  # put a literal string for what we expect because it varies.
  if RUBY_VERSION.to_f == 1.8
    def hash_inspect(hash)
      "\\{(#{hash.map { |key, value| "#{key.inspect} => #{value.inspect}.*" }.join "|"}){#{hash.size}}\\}"
    end
  else
    def hash_inspect(hash)
      RSpec::Matchers::BuiltIn::BaseMatcher::HashFormatting.
        improve_hash_formatting hash.inspect
    end
  end
end

RSpec.configure do |config|
  config.color = true
  config.order = :random

  config.include CommonHelperMethods
  config.include RSpec::Support::InSubProcess

  config.expect_with :rspec do |expectations|
    $default_expectation_syntax = expectations.syntax # rubocop:disable Style/GlobalVars
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.strict_predicate_matchers = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!

  # We don't want rspec-core to look in our `lib` for failure snippets.
  # When it does that, it inevitably finds this line:
  # `RSpec::Support.notify_failure(RSpec::Expectations::ExpectationNotMetError.new message)`
  # ...which isn't very helpful. Far better for it to find the expectation
  # call site in the spec.
  config.project_source_dirs -= ["lib"]
end

RSpec.shared_context "with #should enabled", :uses_should do
  orig_syntax = nil

  before(:all) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.syntax = [:expect, :should]
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end
end

RSpec.shared_context "with the default expectation syntax" do
  orig_syntax = nil

  before(:context) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.reset_syntaxes_to_default
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end

end

RSpec.shared_context "with #should exclusively enabled", :uses_only_should do
  orig_syntax = nil

  before(:context) do
    orig_syntax = RSpec::Matchers.configuration.syntax
    RSpec::Matchers.configuration.syntax = :should
  end

  after(:context) do
    RSpec::Matchers.configuration.syntax = orig_syntax
  end
end

RSpec.shared_context "isolate include_chain_clauses_in_custom_matcher_descriptions" do
  around do |ex|
    orig = RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions?
    ex.run
    RSpec::Expectations.configuration.include_chain_clauses_in_custom_matcher_descriptions = orig
  end
end

RSpec.shared_context "with warn_about_potential_false_positives set to false", :warn_about_potential_false_positives do
  original_value = RSpec::Expectations.configuration.warn_about_potential_false_positives?

  after(:context)  { RSpec::Expectations.configuration.warn_about_potential_false_positives = original_value }
end

module MinitestIntegration
  include ::RSpec::Support::InSubProcess

  def with_minitest_loaded
    in_sub_process do
      with_isolated_stderr do
        require 'minitest/autorun'
      end

      require 'rspec/expectations/minitest_integration'
      yield
    end
  end
end

RSpec::Matchers.define_negated_matcher :avoid_outputting, :output
