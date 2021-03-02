require 'support/aruba_support'

RSpec.describe 'Persistence failures' do
  include_context "aruba support"
  before { setup_aruba }

  context "when `config.example_status_persistence_file_path` is configured" do
    context "to an invalid file path (e.g. spec/spec_helper.rb/examples.txt)" do
      before do
        write_file_formatted "spec/1_spec.rb", "
          RSpec.configure do |c|
            c.example_status_persistence_file_path = 'spec/1_spec.rb/examples.txt'
          end
          RSpec.describe { example { } }
        "
      end

      it 'emits a helpful warning to the user, indicating we cannot write to it, and still runs the spec suite' do
        run_command "spec/1_spec.rb"

        expect(last_cmd_stderr).to include(
          "WARNING: Could not write",
          "spec/1_spec.rb/examples.txt",
          "config.example_status_persistence_file_path",
          "Errno:"
        )
        expect(last_cmd_stdout).to include("1 example")
      end
    end

    context "to a file path for which we lack permissions" do
      before do
        write_file_formatted "spec/1_spec.rb", "
          RSpec.configure do |c|
            c.example_status_persistence_file_path = 'spec/examples.txt'
          end
          RSpec.describe { example { } }
        "

        write_file_formatted "spec/examples.txt", ""
        cd '.' do
          FileUtils.chmod 0000, "spec/examples.txt"
        end
      end


      it 'emits a helpful warning to the user, indicating we cannot read from it, and still runs the spec suite' do
        skip "Legacy builds run as root and this will never pass" if ENV['LEGACY_CI']
        run_command "spec/1_spec.rb"

        expected_snippets = [
          "WARNING: Could not read",
          "spec/examples.txt",
          "config.example_status_persistence_file_path",
          "Errno:"
        ]

        if RSpec::Support::OS.windows?
          # Not sure why, but on windows it doesn't trigger the read error, it
          # triggers a write error instead. The important thing is that whatever
          # system error occurs is reported accurately.
          expected_snippets[0] = "WARNING: Could not write"
        end

        expect(last_cmd_stderr).to include(*expected_snippets)
        expect(last_cmd_stdout).to include("1 example")
      end
    end
  end
end
