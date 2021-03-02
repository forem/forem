module FormatterSupport
  def run_example_specs_with_formatter(formatter_option, options={}, &block)
    output = run_rspec_with_formatter(formatter_option, options.merge(:extra_options => ["spec/rspec/core/resources/formatter_specs.rb"]), &block)

    return output unless options.fetch(:normalize_output, true)
    output = normalize_durations(output)

    caller_line = RSpec::Core::Metadata.relative_path(caller.first)
    output.lines.reject do |line|
      # remove the direct caller as that line is different for the summary output backtraces
      line.include?(caller_line) ||

      # ignore scirpt/rspec_with_simplecov because we don't usually have it locally but
      # do have it on travis
      line.include?("script/rspec_with_simplecov") ||

      # this line varies a bit depending on how you run the specs (via `rake` vs `rspec`)
      line.include?('/exe/rspec:')
    end.join
  end

  def run_rspec_with_formatter(formatter, options={})
    extra_options = options.fetch(:extra_options) { [] }

    spec_order = options[:seed] ? ["--seed", options[:seed].to_s] : ["--order", "defined"]

    options = RSpec::Core::ConfigurationOptions.new([
      "--no-profile", "--format", formatter, *(spec_order + extra_options)
    ])

    err, out = StringIO.new, StringIO.new
    err.set_encoding("utf-8") if err.respond_to?(:set_encoding)

    runner = RSpec::Core::Runner.new(options)
    configuration = runner.configuration
    configuration.backtrace_formatter.exclusion_patterns << /rspec_with_simplecov/
    configuration.backtrace_formatter.inclusion_patterns = []

    yield runner if block_given?

    runner.run(err, out)
    out.string
  end

  def normalize_durations(output)
    output.gsub(/(?:\d+ minutes? )?\d+(?:\.\d+)?(s| seconds?)/) do |dur|
      suffix = $1 == "s" ? "s" : " seconds"
      "n.nnnn#{suffix}"
    end
  end

  if RUBY_VERSION.to_f < 1.9
    def expected_summary_output_for_example_specs
      <<-EOS.gsub(/^\s+\|/, '').chomp
        |Pending: (Failures listed here are expected and do not affect your suite's status)
        |
        |  1) pending spec with no implementation is pending
        |     # Not yet implemented
        |     # ./spec/rspec/core/resources/formatter_specs.rb:11
        |
        |  2) pending command with block format with content that would fail is pending
        |     # No reason given
        |     Failure/Error: expect(1).to eq(2)
        |
        |       expected: 2
        |            got: 1
        |
        |       (compared using ==)
        |     # ./spec/rspec/core/resources/formatter_specs.rb:18
        |     # ./spec/support/formatter_support.rb:41:in `run_rspec_with_formatter'
        |     # ./spec/support/formatter_support.rb:3:in `run_example_specs_with_formatter'
        |     # ./spec/support/sandboxing.rb:16
        |     # ./spec/support/sandboxing.rb:7
        |
        |Failures:
        |
        |  1) pending command with block format behaves like shared is marked as pending but passes FIXED
        |     Expected pending 'No reason given' to fail. No error was raised.
        |     Shared Example Group: "shared" called from ./spec/rspec/core/resources/formatter_specs.rb:22
        |     # ./spec/rspec/core/resources/formatter_specs.rb:4
        |
        |  2) failing spec fails
        |     Failure/Error: expect(1).to eq(2)
        |
        |       expected: 2
        |            got: 1
        |
        |       (compared using ==)
        |     # ./spec/rspec/core/resources/formatter_specs.rb:37
        |     # ./spec/support/formatter_support.rb:41:in `run_rspec_with_formatter'
        |     # ./spec/support/formatter_support.rb:3:in `run_example_specs_with_formatter'
        |     # ./spec/support/sandboxing.rb:16
        |     # ./spec/support/sandboxing.rb:7
        |
        |  3) failing spec fails twice
        |     Got 2 failures:
        |
        |     3.1) Failure/Error: expect(1).to eq(2)
        |
        |            expected: 2
        |                 got: 1
        |
        |            (compared using ==)
        |          # ./spec/rspec/core/resources/formatter_specs.rb:41
        |
        |     3.2) Failure/Error: expect(3).to eq(4)
        |
        |            expected: 4
        |                 got: 3
        |
        |            (compared using ==)
        |          # ./spec/rspec/core/resources/formatter_specs.rb:42
        |
        |  4) a failing spec with odd backtraces fails with a backtrace that has no file
        |     Failure/Error: Unable to find (erb) to read failed line
        |
        |     RuntimeError:
        |       foo
        |     # (erb):1
        |
        |  5) a failing spec with odd backtraces fails with a backtrace containing an erb file
        |     Failure/Error: Unable to find /foo.html.erb to read failed line
        |
        |     Exception:
        |       Exception
        |     # /foo.html.erb:1:in `<main>': foo (RuntimeError)
        |
        |  6) a failing spec with odd backtraces with a `nil` backtrace raises
        |     Failure/Error: Unable to find matching line from backtrace
        |
        |     RuntimeError:
        |       boom
        |
        |Finished in n.nnnn seconds (files took n.nnnn seconds to load)
        |10 examples, 6 failures, 2 pending
        |
        |Failed examples:
        |
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:4 # pending command with block format behaves like shared is marked as pending but passes
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:36 # failing spec fails
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:40 # failing spec fails twice
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:47 # a failing spec with odd backtraces fails with a backtrace that has no file
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:53 # a failing spec with odd backtraces fails with a backtrace containing an erb file
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:71 # a failing spec with odd backtraces with a `nil` backtrace raises
      EOS
    end
  else
    def expected_summary_output_for_example_specs
      <<-EOS.gsub(/^\s+\|/, '').chomp
        |Pending: (Failures listed here are expected and do not affect your suite's status)
        |
        |  1) pending spec with no implementation is pending
        |     # Not yet implemented
        |     # ./spec/rspec/core/resources/formatter_specs.rb:11
        |
        |  2) pending command with block format with content that would fail is pending
        |     # No reason given
        |     Failure/Error: expect(1).to eq(2)
        |
        |       expected: 2
        |            got: 1
        |
        |       (compared using ==)
        |     # ./spec/rspec/core/resources/formatter_specs.rb:18:in `block (3 levels) in <top (required)>'
        |     # ./spec/support/formatter_support.rb:41:in `run_rspec_with_formatter'
        |     # ./spec/support/formatter_support.rb:3:in `run_example_specs_with_formatter'
        |     # ./spec/support/sandboxing.rb:16:in `block (3 levels) in <top (required)>'
        |     # ./spec/support/sandboxing.rb:7:in `block (2 levels) in <top (required)>'
        |
        |Failures:
        |
        |  1) pending command with block format behaves like shared is marked as pending but passes FIXED
        |     Expected pending 'No reason given' to fail. No error was raised.
        |     Shared Example Group: "shared" called from ./spec/rspec/core/resources/formatter_specs.rb:22
        |     # ./spec/rspec/core/resources/formatter_specs.rb:4
        |
        |  2) failing spec fails
        |     Failure/Error: expect(1).to eq(2)
        |
        |       expected: 2
        |            got: 1
        |
        |       (compared using ==)
        |     # ./spec/rspec/core/resources/formatter_specs.rb:37:in `block (2 levels) in <top (required)>'
        |     # ./spec/support/formatter_support.rb:41:in `run_rspec_with_formatter'
        |     # ./spec/support/formatter_support.rb:3:in `run_example_specs_with_formatter'
        |     # ./spec/support/sandboxing.rb:16:in `block (3 levels) in <top (required)>'
        |     # ./spec/support/sandboxing.rb:7:in `block (2 levels) in <top (required)>'
        |
        |  3) failing spec fails twice
        |     Got 2 failures:
        |
        |     3.1) Failure/Error: expect(1).to eq(2)
        |
        |            expected: 2
        |                 got: 1
        |
        |            (compared using ==)
        |          # ./spec/rspec/core/resources/formatter_specs.rb:41:in `block (2 levels) in <top (required)>'
        |
        |     3.2) Failure/Error: expect(3).to eq(4)
        |
        |            expected: 4
        |                 got: 3
        |
        |            (compared using ==)
        |          # ./spec/rspec/core/resources/formatter_specs.rb:42:in `block (2 levels) in <top (required)>'
        |
        |  4) a failing spec with odd backtraces fails with a backtrace that has no file
        |     Failure/Error: ERB.new("<%= raise 'foo' %>").result
        |
        |     RuntimeError:
        |       foo
        |     # (erb):1:in `<main>'
        |     # ./spec/rspec/core/resources/formatter_specs.rb:50:in `block (2 levels) in <top (required)>'
        |     # ./spec/support/formatter_support.rb:41:in `run_rspec_with_formatter'
        |     # ./spec/support/formatter_support.rb:3:in `run_example_specs_with_formatter'
        |     # ./spec/support/sandboxing.rb:16:in `block (3 levels) in <top (required)>'
        |     # ./spec/support/sandboxing.rb:7:in `block (2 levels) in <top (required)>'
        |
        |  5) a failing spec with odd backtraces fails with a backtrace containing an erb file
        |     Failure/Error: Unable to find /foo.html.erb to read failed line
        |
        |     Exception:
        |       Exception
        |     # /foo.html.erb:1:in `<main>': foo (RuntimeError)
        |
        |  6) a failing spec with odd backtraces with a `nil` backtrace raises
        |     Failure/Error: Unable to find matching line from backtrace
        |
        |     RuntimeError:
        |       boom
        |
        |Finished in n.nnnn seconds (files took n.nnnn seconds to load)
        |10 examples, 6 failures, 2 pending
        |
        |Failed examples:
        |
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:4 # pending command with block format behaves like shared is marked as pending but passes
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:36 # failing spec fails
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:40 # failing spec fails twice
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:47 # a failing spec with odd backtraces fails with a backtrace that has no file
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:53 # a failing spec with odd backtraces fails with a backtrace containing an erb file
        |rspec ./spec/rspec/core/resources/formatter_specs.rb:71 # a failing spec with odd backtraces with a `nil` backtrace raises
      EOS
    end
  end

  def send_notification type, notification
    reporter.notify type, notification
  end

  def reporter
    @reporter ||= setup_reporter
  end

  def setup_reporter(*streams)
    streams << config.output_stream if streams.empty?
    config.formatter_loader.add described_class, *streams
    @formatter = config.formatters.first
    @reporter = config.reporter
  end

  def setup_profiler
    config.profile_examples = true
  end

  def formatter_output
    @formatter_output ||= StringIO.new
  end

  def config
    @configuration ||=
      begin
        config = RSpec::Core::Configuration.new
        config.output_stream = formatter_output
        config
      end
  end

  def configure
    yield config
  end

  def formatter
    @formatter ||=
      begin
        setup_reporter
        @formatter
      end
  end

  def new_example(metadata = {})
    metadata = metadata.dup
    result = RSpec::Core::Example::ExecutionResult.new
    result.started_at = ::Time.now
    result.record_finished(metadata.delete(:status) { :passed }, ::Time.now)
    result.exception = Exception.new if result.status == :failed

    instance_double(RSpec::Core::Example,
                     :description             => "Example",
                     :full_description        => "Example",
                     :example_group           => group,
                     :execution_result        => result,
                     :location                => "",
                     :location_rerun_argument => "",
                     :metadata                => {
                       :shared_group_inclusion_backtrace => []
                     }.merge(metadata)
                   )
  end

  def examples(n)
    Array.new(n) { new_example }
  end

  def group
    group = class_double "RSpec::Core::ExampleGroup", :description => "Group"
    allow(group).to receive(:parent_groups) { [group] }
    group
  end

  def start_notification(count)
   ::RSpec::Core::Notifications::StartNotification.new count
  end

  def stop_notification
   ::RSpec::Core::Notifications::ExamplesNotification.new reporter
  end

  def example_notification(specific_example = new_example)
   ::RSpec::Core::Notifications::ExampleNotification.for specific_example
  end

  def group_notification group_to_notify = group
   ::RSpec::Core::Notifications::GroupNotification.new group_to_notify
  end

  def message_notification(message)
    ::RSpec::Core::Notifications::MessageNotification.new message
  end

  def null_notification
    ::RSpec::Core::Notifications::NullNotification
  end

  def seed_notification(seed, used = true)
    ::RSpec::Core::Notifications::SeedNotification.new seed, used
  end

  def failed_examples_notification
    ::RSpec::Core::Notifications::ExamplesNotification.new reporter
  end

  def summary_notification(duration, examples, failed, pending, time, errors = 0)
    ::RSpec::Core::Notifications::SummaryNotification.new duration, examples, failed, pending, time, errors
  end

  def profile_notification(duration, examples, number)
    ::RSpec::Core::Notifications::ProfileNotification.new duration, examples, number, reporter.instance_variable_get('@profiler').example_groups
  end

end

if RSpec::Support::RubyFeatures.module_prepends_supported?
  module RSpec::Core
    class Reporter
      module EnforceRSpecNotificationsListComplete
        def notify(event, *args)
          return super if caller_locations(1, 1).first.label =~ /publish/
          return super if RSPEC_NOTIFICATIONS.include?(event)

          raise "#{event.inspect} must be added to `RSPEC_NOTIFICATIONS`"
        end
      end

      prepend EnforceRSpecNotificationsListComplete
    end
  end
end
