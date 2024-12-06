require "rspec"

# To help produce better bug reports in Rubinius
if RUBY_ENGINE == "rbx"
  $DEBUG = true # would be nice if this didn't fail ... :(
  require "rspec/matchers"
  require "rspec/matchers/built_in/be"
end

if ENV["CI"]
  require "coveralls"
  Coveralls.wear!
end

rspec_version = ::RSpec::Version::STRING.to_f
old_rspec = (rspec_version < 3)

if old_rspec
  module RSpec
    module Core
      class ExampleGroup
        def instance_double(*args)
          double(*args)
        end
      end
    end
  end
end

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.register_ordering :global do |examples|
    examples.partition { |ex| ex.metadata[:type] != :acceptance }.flatten(1)
  end

  # Use global for running acceptance tests last
  config.order = :global

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"

    unless old_rspec
      if rspec_version > 3.0
        expectations.include_chain_clauses_in_custom_matcher_descriptions = true
      end
    end
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true unless old_rspec
  end

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run focus: ENV["CI"] != "true"
  config.run_all_when_everything_filtered = true

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended.
  # For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching

  config.disable_monkey_patching! unless old_rspec

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  # config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 10

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.raise_errors_for_deprecations!

  config.before do
    %w(exist?).each do |meth|
      allow(Dir).to receive(meth.to_sym) do |*args|
        abort "stub me: Dir.#{meth}(#{args.map(&:inspect) * ','})!"
      end
    end

    allow(Dir).to receive(:[]) do |*args|
      abort "stub me: Dir[#{args.first}]!"
    end

    unless RUBY_ENGINE == "rbx"
      # RBX uses cache in ~/.rbx
      %w(directory?).each do |meth|
        allow(File).to receive(meth.to_sym) do |*args|
          abort "stub me: File.#{meth}(#{args.map(&:inspect) * ','})!"
        end
      end
    end

    %w(delete readlines).each do |meth|
      allow(File).to receive(meth.to_sym) do |*args|
        abort "stub me: File.#{meth}(#{args.map(&:inspect) * ','})!"
      end
    end

    %w(mkdir mkdir_p).each do |meth|
      allow(FileUtils).to receive(meth.to_sym) do |*args|
        abort "stub me: FileUtils.#{meth}(#{args.map(&:inspect) * ','})!"
      end
    end

    %w(spawn system).each do |meth|
      allow(Kernel).to receive(meth.to_sym) do |*args|
        abort "stub me: Kernel.#{meth}(#{args.map(&:inspect) * ','})!"
      end
    end
  end
end
