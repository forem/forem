require 'rspec/core/formatters/documentation_formatter'

module RSpec::Core::Formatters
  RSpec.describe DocumentationFormatter do
    include FormatterSupport

    before do
      send_notification :start, start_notification(2)
    end

    def execution_result(values)
      RSpec::Core::Example::ExecutionResult.new.tap do |er|
        values.each { |name, value| er.__send__(:"#{name}=", value) }
      end
    end

    it "numbers the failures" do
      send_notification :example_failed, example_notification( double("example 1",
               :description => "first example",
               :full_description => "group first example",
               :execution_result => execution_result(:status => :failed, :exception => Exception.new),
               :metadata => {}
              ))
      send_notification :example_failed, example_notification( double("example 2",
               :description => "second example",
               :full_description => "group second example",
               :execution_result => execution_result(:status => :failed, :exception => Exception.new),
               :metadata => {}
              ))

      expect(formatter_output.string).to match(/first example \(FAILED - 1\)/m)
      expect(formatter_output.string).to match(/second example \(FAILED - 2\)/m)
    end

    it 'will not error if more finishes than starts are called' do
      group =
        double("example 1",
               :description => "first example",
               :full_description => "group first example",
               :metadata => {},
               :top_level? => true,
               :top_level_description => "Top group"
              )

      send_notification :example_group_finished, group_notification(group)
      send_notification :example_group_finished, group_notification(group)
      send_notification :example_group_finished, group_notification(group)

      expect {
        send_notification :example_group_started, group_notification(group)
      }.not_to raise_error
    end

    it "represents nested group using hierarchy tree" do
      group = RSpec.describe("root")
      context1 = group.describe("context 1")
      context1.example("nested example 1.1"){}
      context1.example("nested example 1.2"){}

      context11 = context1.describe("context 1.1")
      context11.example("nested example 1.1.1"){}
      context11.example("nested example 1.1.2"){}

      context2 = group.describe("context 2")
      context2.example("nested example 2.1"){}
      context2.example("nested example 2.2"){}

      group.run(reporter)

      expect(formatter_output.string).to eql("
root
  context 1
    nested example 1.1
    nested example 1.2
    context 1.1
      nested example 1.1.1
      nested example 1.1.2
  context 2
    nested example 2.1
    nested example 2.2
")
    end

    it "can output indented messages from within example group" do
      root = RSpec.describe("root")
      root.example("example") {|example| example.reporter.message("message")}

      root.run(reporter)

      expect(formatter_output.string).to eql("
root
  example
    message
")
    end

    it "can output indented messages" do
      root = RSpec.describe("root")
      context = root.describe("nested")
      context.example("example") {}

      root.run(reporter)

      reporter.message("message")

      expect(formatter_output.string).to eql("
root
  nested
    example
message
")
    end

    it "strips whitespace for each row" do
      group = RSpec.describe(" root ")
      context1 = group.describe(" nested ")
      context1.example(" example 1 ") {}
      context1.example(" example 2 ", :pending => true){ fail }
      context1.example(" example 3 ") { fail }

      group.run(reporter)

      expect(formatter_output.string).to eql("
root
  nested
    example 1
    example 2 (PENDING: No reason given)
    example 3 (FAILED - 1)
")
    end

    # The backtrace is slightly different on JRuby/Rubinius so we skip there.
    it 'produces the expected full output', :if => RSpec::Support::Ruby.mri? do
      output = run_example_specs_with_formatter("doc")
      output.gsub!(/ +$/, '') # strip trailing whitespace

      expect(output).to eq(<<-EOS.gsub(/^\s+\|/, ''))
        |
        |pending spec with no implementation
        |  is pending (PENDING: Not yet implemented)
        |
        |pending command with block format
        |  with content that would fail
        |    is pending (PENDING: No reason given)
        |  behaves like shared
        |    is marked as pending but passes (FAILED - 1)
        |
        |passing spec
        |  passes
        |  passes with a multiple
        |     line description
        |
        |failing spec
        |  fails (FAILED - 2)
        |  fails twice (FAILED - 3)
        |
        |a failing spec with odd backtraces
        |  fails with a backtrace that has no file (FAILED - 4)
        |  fails with a backtrace containing an erb file (FAILED - 5)
        |  with a `nil` backtrace
        |    raises (FAILED - 6)
        |
        |#{expected_summary_output_for_example_specs}

      EOS
    end
  end
end
