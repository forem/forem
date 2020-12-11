require 'support/aruba_support'

RSpec.describe 'Fail if no examples' do
  include_context "aruba support"
  before { setup_aruba }

  context 'when 1 passing example' do
    def passing_example(fail_if_no_examples)
      "
        RSpec.configure { |c| c.fail_if_no_examples = #{fail_if_no_examples} }

        RSpec.describe 'something' do
          it 'succeeds' do
            true
          end
        end
      "
    end

    it 'succeeds if fail_if_no_examples set to true' do
      write_file 'spec/example_spec.rb', passing_example(true)
      run_command ""
      expect(last_cmd_stdout).to include("1 example, 0 failures")
      expect(last_cmd_exit_status).to eq(0)
    end

    it 'succeeds if fail_if_no_examples set to false' do
      write_file 'spec/example_spec.rb', passing_example(false)
      run_command ""
      expect(last_cmd_stdout).to include("1 example, 0 failures")
      expect(last_cmd_exit_status).to eq(0)
    end
  end

  context 'when 1 failing example' do
    def failing_example(fail_if_no_examples)
      "
        RSpec.configure { |c| c.fail_if_no_examples = #{fail_if_no_examples} }

        RSpec.describe 'something' do
          it 'fails' do
            fail
          end
        end
      "
    end

    it 'fails if fail_if_no_examples set to true' do
      write_file 'spec/example_spec.rb', failing_example(true)
      run_command ""
      expect(last_cmd_stdout).to include("1 example, 1 failure")
      expect(last_cmd_exit_status).to eq(1)
    end

    it 'fails if fail_if_no_examples set to false' do
      write_file 'spec/example_spec.rb', failing_example(false)
      run_command ""
      expect(last_cmd_stdout).to include("1 example, 1 failure")
      expect(last_cmd_exit_status).to eq(1)
    end
  end

  context 'when 0 examples' do
    def no_examples(fail_if_no_examples)
      "
        RSpec.configure { |c| c.fail_if_no_examples = #{fail_if_no_examples} }

        RSpec.describe 'something' do
        end
      "
    end

    it 'fails if fail_if_no_examples set to true' do
      write_file 'spec/example_spec.rb', no_examples(true)
      run_command ""
      expect(last_cmd_stdout).to include("0 examples, 0 failures")
      expect(last_cmd_exit_status).to eq(1)
    end

    it 'succeeds if fail_if_no_examples set to false' do
      write_file 'spec/example_spec.rb', no_examples(false)
      run_command ""
      expect(last_cmd_stdout).to include("0 examples, 0 failures")
      expect(last_cmd_exit_status).to eq(0)
    end

    context 'when custom failure_exit_code set' do
      def no_examples_custom_failure_exit_code(fail_if_no_examples)
        "
          RSpec.configure do |c|
            c.fail_if_no_examples = #{fail_if_no_examples}
            c.failure_exit_code = 15
          end

          RSpec.describe 'something' do
          end
        "
      end

      it 'fails if fail_if_no_examples set to true' do
        write_file 'spec/example_spec.rb', no_examples_custom_failure_exit_code(true)
        run_command ""
        expect(last_cmd_stdout).to include("0 examples, 0 failures")
        expect(last_cmd_exit_status).to eq(15)
      end
    end
  end
end
