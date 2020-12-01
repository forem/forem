require 'support/aruba_support'

RSpec.describe 'Filtering' do
  include_context "aruba support"
  before { setup_aruba }

  it 'prints a rerun command for shared examples in external files that works to rerun' do
    write_file "spec/support/shared_examples.rb", "
      RSpec.shared_examples 'with a failing example' do
        example { expect(1).to eq(2) } # failing
        example { expect(2).to eq(2) } # passing
      end
    "

    write_file "spec/host_group_spec.rb", "
      load File.expand_path('../support/shared_examples.rb', __FILE__)

      RSpec.describe 'A group with shared examples' do
        include_examples 'with a failing example'
      end

      RSpec.describe 'A group with a passing example' do
        example { expect(1).to eq(1) }
      end
    "

    run_command ""
    expect(last_cmd_stdout).to include("3 examples, 1 failure")
    run_rerun_command_for_failing_spec
    expect(last_cmd_stdout).to include("1 example, 1 failure")
    # There was originally a bug when doing it again...
    run_rerun_command_for_failing_spec
    expect(last_cmd_stdout).to include("1 example, 1 failure")
  end

  def run_rerun_command_for_failing_spec
    command = last_cmd_stdout[/Failed examples:\s+rspec (\S+) #/, 1]
    run_command command
  end

  context "with a shared example containing a context in a separate file" do
    it "runs the example nested inside the shared" do
      write_file_formatted 'spec/shared_example.rb', "
        RSpec.shared_examples_for 'a shared example' do
          it 'succeeds' do
          end

          context 'with a nested context' do
            it 'succeeds (nested)' do
            end
          end
        end
      "

      write_file_formatted 'spec/simple_spec.rb', "
        require File.join(File.dirname(__FILE__), 'shared_example.rb')

        RSpec.describe 'top level' do
          it_behaves_like 'a shared example'
        end
      "

      run_command 'spec/simple_spec.rb:3 -fd'
      expect(last_cmd_stdout).to match(/2 examples, 0 failures/)
    end
  end

  context "passing a line-number filter" do
    it "works with different custom runners used in the same process" do
      result_counter = Class.new do
        RSpec::Core::Formatters.register(self, :example_passed)

        attr_accessor :passed_examples

        def initialize(*)
          @passed_examples = 0
        end

        def example_passed(notification)
          @passed_examples += 1
        end
      end

      spec_file = "spec/filtering_custom_runner_spec.rb"

      write_file_formatted spec_file, "
        RSpec.describe 'A group' do
          example('ex 1') { }
          example('ex 2') { }
        end
      "

      spec_file_path = expand_path(spec_file)

      formatter = result_counter.new
      RSpec.configuration.add_formatter(formatter)
      opts = RSpec::Core::ConfigurationOptions.new(["#{spec_file_path}[1:1]"])
      RSpec::Core::Runner.new(opts).run(StringIO.new, StringIO.new)

      expect(formatter.passed_examples).to eq 1

      RSpec.clear_examples

      formatter = result_counter.new
      RSpec.configuration.add_formatter(formatter)
      opts = RSpec::Core::ConfigurationOptions.new(["#{spec_file_path}[1:2]"])
      RSpec::Core::Runner.new(opts).run(StringIO.new, StringIO.new)

      expect(formatter.passed_examples).to eq 1
    end

    it "trumps exclusions, except for :if/:unless (which are absolute exclusions)" do
      write_file_formatted 'spec/a_spec.rb', "
        RSpec.configure do |c|
          c.filter_run_excluding :slow
        end

        RSpec.describe 'A slow group', :slow do
          example('ex 1') { }
          example('ex 2') { }
        end

        RSpec.describe 'A group with a slow example' do
          example('ex 3'              ) { }
          example('ex 4', :slow       ) { }
          example('ex 5', :if => false) { }
        end
      "

      run_command "spec/a_spec.rb -fd"
      expect(last_cmd_stdout).to include("1 example, 0 failures", "ex 3").and exclude("ex 1", "ex 2", "ex 4", "ex 5")

      run_command "spec/a_spec.rb:5 -fd" # selecting 'A slow group'
      expect(last_cmd_stdout).to include("2 examples, 0 failures", "ex 1", "ex 2").and exclude("ex 3", "ex 4", "ex 5")

      run_command "spec/a_spec.rb:12 -fd" # selecting slow example
      expect(last_cmd_stdout).to include("1 example, 0 failures", "ex 4").and exclude("ex 1", "ex 2", "ex 3", "ex 5")

      run_command "spec/a_spec.rb:13 -fd" # selecting :if => false example
      expect(last_cmd_stdout).to include("0 examples, 0 failures").and exclude("ex 1", "ex 2", "ex 3", "ex 4", "ex 5")
    end

    it 'works correctly when line numbers align with a shared example group line number from another file' do
      write_file_formatted 'spec/support/shared_examples_with_matching_line.rb', "
        # line 1
        # line 2
        # line 3
        RSpec.shared_examples_for 'shared examples' do # line 4
          it 'fails' do # line 5
            fail 'shared example'
          end
        end
      "

      write_file_formatted 'spec/some_spec.rb', "
        require File.expand_path('../support/shared_examples_with_matching_line', __FILE__) # line 1
        RSpec.describe 'A group' do # line 2
          it_behaves_like 'shared examples' # line 3
          # line 4
          it 'passes' do # line 5
            expect(1).to eq(1)
          end
        end
      "

      run_command "spec/some_spec.rb:5"
      expect(last_cmd_stdout).to include("1 example, 0 failures")
    end
  end

  context "passing a line-number-filtered file and a non-filtered file" do
    it "applies the line number filtering only to the filtered file, running all specs in the non-filtered file except excluded ones" do
      write_file_formatted "spec/file_1_spec.rb", "
        RSpec.describe 'File 1' do
          it('passes') {      }
          it('fails')  { fail }
        end
      "

      write_file_formatted "spec/file_2_spec.rb", "
        RSpec.configure do |c|
          c.filter_run_excluding :exclude_me
        end

        RSpec.describe 'File 2' do
          it('passes') { }
          it('passes') { }
          it('fails', :exclude_me) { fail }
        end
      "

      run_command "spec/file_1_spec.rb:2 spec/file_2_spec.rb -fd"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)
      expect(last_cmd_stdout).not_to match(/fails/)
    end

    it 'applies command line tag filters only to files that lack a line number filter' do
      write_file_formatted "spec/file_1_spec.rb", "
        RSpec.describe 'File 1' do
          it('is selected by line')   { }
          it('is not selected', :tag) { }
        end
      "

      write_file_formatted "spec/file_2_spec.rb", "
        RSpec.describe 'File 2' do
          it('is not selected')          { }
          it('is selected by tag', :tag) { }
        end
      "

      run_command "spec/file_1_spec.rb:2 spec/file_2_spec.rb --tag tag -fd"
      expect(last_cmd_stdout).to include(
        "2 examples, 0 failures",
        "is selected by line", "is selected by tag"
      ).and exclude("not selected")
    end
  end

  context "passing example ids at the command line" do
    it "selects matching examples" do
      write_file_formatted "spec/file_1_spec.rb", "
        RSpec.describe 'File 1' do
          1.upto(3) do |i|
            example('ex ' + i.to_s) { expect(i).to be_odd }
          end
        end
      "

      write_file_formatted "spec/file_2_spec.rb", "
        RSpec.describe 'File 2' do
          1.upto(3) do |i|
            example('ex ' + i.to_s) { expect(i).to be_even }
          end
        end
      "

      # Using the form that Metadata.relative_path returns...
      run_command "./spec/file_1_spec.rb[1:1,1:3] ./spec/file_2_spec.rb[1:2]"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)

      # Using spaces between scoped ids, and quoting the whole thing...
      run_command "'./spec/file_1_spec.rb[1:1, 1:3]' ./spec/file_2_spec.rb[1:2]"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)

      # Without the leading `.`...
      run_command "spec/file_1_spec.rb[1:1,1:3] spec/file_2_spec.rb[1:2]"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)

      # Using absolute paths...
      spec_root = cd('.') { File.expand_path("spec") }
      run_command "#{spec_root}/file_1_spec.rb[1:1,1:3] #{spec_root}/file_2_spec.rb[1:2]"
      expect(last_cmd_stdout).to match(/3 examples, 0 failures/)
    end

    it "selects matching example groups" do
      write_file_formatted "spec/file_1_spec.rb", "
        RSpec.describe 'Group 1' do
          example { fail }

          context 'nested 1' do
            it { }
            it { }
          end

          context 'nested 2' do
            example { fail }
          end
        end
      "

      run_command "./spec/file_1_spec.rb[1:2]"
      expect(last_cmd_stdout).to match(/2 examples, 0 failures/)
    end
  end

  context "with `filter_run_when_matching`" do
    it "filters to matching examples" do
      write_file_formatted "spec/example_spec.rb", "
        RSpec.configure do |c|
          c.filter_run_when_matching :some_tag
        end

        RSpec.describe 'A matching group', :some_tag do
          it 'passes' do
          end
        end

        RSpec.describe 'An unmatching group' do
          it 'passes', :some_tag do
          end

          it 'fails' do
            raise 'boom'
          end
        end
      "

      run_command ""
      expect(last_cmd_stdout).to include("2 examples, 0 failures")
    end

    it "is ignored when no examples match the provided filter" do
      write_file_formatted "spec/example_spec.rb", "
        RSpec.configure do |c|
          c.filter_run_when_matching :some_tag
        end

        RSpec.describe 'A group' do
          it 'is still run' do
          end
        end
      "

      run_command ""
      expect(last_cmd_stdout).to include("1 example, 0 failures")
    end
  end
end
