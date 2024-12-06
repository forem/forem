require "guard/compat/test/helper"

require "guard/rspec/rspec_process"

RSpec.describe Guard::RSpec::RSpecProcess do
  let(:results) { instance_double(Guard::RSpec::Results) }

  let(:cmd) { "foo" }
  let(:file) { "/tmp/foobar.txt" }
  let(:pid) { 1234 }
  let(:exit_code) { 0 }
  let(:status) { instance_double(Process::Status, exitstatus: exit_code) }
  let(:wait_result) { [pid, status] }

  subject do
    described_class.new(cmd, file)
  end

  before do
    allow(Kernel).to receive(:spawn).
      with({ "GUARD_RSPEC_RESULTS_FILE" => file }, cmd).and_return(pid)

    allow(Guard::RSpec::Results).to receive(:new).
      with(file).and_return(results)

    allow(Guard::Compat::UI).to receive(:debug)
  end

  context "with an non-existing command" do
    before do
      allow(Kernel).to receive(:spawn).
        and_raise(Errno::ENOENT, "No such file or directory - foo")
    end

    it "fails" do
      expect { subject }.
        to raise_error(Guard::RSpec::RSpecProcess::Failure, /Failed: /)
    end
  end

  context "with an existing command" do
    before do
      allow(Process).to receive(:wait2).with(pid).and_return(wait_result)
    end

    context "with an unknown failure" do
      let(:exit_code) { 100 }

      it "fails" do
        expect { subject }.
          to raise_error(Guard::RSpec::RSpecProcess::Failure, /Failed: /)
      end
    end

    context "without any exit code" do
      let(:exit_code) { nil }

      it "fails" do
        expect { subject }.
          to raise_error(Guard::RSpec::RSpecProcess::Failure, /Failed: /)
      end
    end

    context "with the failure code for normal test failures" do
      let(:exit_code) { Guard::RSpec::Command::FAILURE_EXIT_CODE }

      it "fails" do
        expect { subject }.to_not raise_error
      end

      it { is_expected.to_not be_all_green }
    end

    context "with no failures" do
      it "waits for process to end" do
        expect(Process).to receive(:wait2).with(pid).and_return(wait_result)
        subject
      end

      it { is_expected.to be_all_green }

      context "with a relative results file path" do
        before do
          allow(Guard::Compat::UI).to receive(:warning)
        end
        let(:file) { "foobar.txt" }

        it "shows a warning" do
          expect(Guard::Compat::UI).to receive(:warning).
            with(/is not an absolute path/)
          subject
        end
      end

      context "with a missing results file" do
        before do
          allow(Guard::Compat::UI).to receive(:error)
        end
        before do
          allow(Guard::RSpec::Results).to receive(:new).
            with(file).and_raise(Errno::ENOENT, "foobar.txt")
        end

        it "shows a message" do
          expect(Guard::Compat::UI).to receive(:error).
            with(/cannot open results file/)

          begin
            subject
          rescue Errno::ENOENT
            nil
          end
        end

        it "fails with an error" do
          expect { subject }.to raise_error(
            Errno::ENOENT,
            /No such file or directory - foobar/
          )
        end
      end
    end

    context "with bundler_env option" do
      it "runs without Bunder changes when :inherit" do
        expect(Bundler).to_not receive(:with_clean_env)
        expect(Bundler).to_not receive(:with_original_env)

        described_class.new(cmd, file, bundler_env: :inherit)
      end

      it "runs on clean Bunder changes when :clean_env" do
        expect(Bundler).to receive(:with_clean_env)

        described_class.new(cmd, file, bundler_env: :clean_env)
      end

      it "runs on original Bunder changes when :original_env" do
        expect(Bundler).to receive(:with_original_env)

        described_class.new(cmd, file, bundler_env: :original_env)
      end
    end

    context "without bundler_env option" do
      it "runs on original Bunder" do
        expect(Bundler).to receive(:with_original_env)
        subject
      end
    end
  end
end
