require "shellany/sheller"

RSpec.describe Shellany::Sheller, :sheller_specs do
  before do
    allow(Kernel).to receive(:system) do |args|
      fail "Stub called with: #{args.inspect}"
    end
  end

  subject { described_class }

  context "without a command" do
    [:new, :run, :stdout, :stderr].each do |meth|
      describe ".#{meth}" do
        specify do
          expect { subject.send(meth) }.
            to raise_error ArgumentError, "no command given"
        end
      end
    end
  end

  context "with shell (string) cmd returning success" do
    let(:cmd) { "ls -l" }
    let(:output) { "foo.rb\n" }
    let(:errors) { "" }
    let(:result) do
      [instance_double(Process::Status, success?: true), output, errors]
    end

    context "when constructed with a cmd" do
      subject { described_class.new(cmd) }

      describe "#run" do
        it "runs the command given to constructor" do
          expect(described_class).to receive(:_system_with_capture).
            with(cmd).and_return(result)
          subject.run
        end
      end
    end
  end

  context "with array cmd returning success" do
    let(:cmd) { %w(ls -l) }
    let(:output) { "foo.rb\n" }
    let(:errors) { "" }
    let(:result) do
      [instance_double(Process::Status, success?: true), output, errors]
    end

    describe "when used as class" do
      describe ".run" do
        it "runs the given command" do
          expect(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
          subject.run(*cmd)
        end
      end

      describe ".new" do
        it "does not run anything" do
          expect(described_class).to_not receive(:_system_with_capture)
          subject
        end
      end

      describe ".stdout" do
        before do
          allow(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
        end

        it "runs command and returns output" do
          expect(subject.stdout(*cmd)).to eq "foo.rb\n"
        end
      end

      describe ".stderr" do
        before do
          allow(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
        end

        it "runs command and returns errors" do
          expect(subject.stderr(*cmd)).to eq ""
        end
      end
    end

    context "when constructed with a cmd" do
      subject { described_class.new(*cmd) }

      it "does not run anything" do
        expect(described_class).to_not receive(:_system_with_capture)
        subject
      end

      describe "#run" do
        it "runs the command given to constructor" do
          expect(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
          subject.run
        end
      end

      describe "#stdout" do
        before do
          allow(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
        end

        it "runs command and returns output" do
          expect(subject.stdout).to eq "foo.rb\n"
        end
      end

      describe "#stderr" do
        before do
          allow(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
        end

        it "runs command and returns output" do
          expect(subject.stderr).to eq ""
        end
      end

      describe "#ok?" do
        before do
          allow(described_class).to receive(:_system_with_capture).
            with(*cmd) { result }
        end

        it "runs command and returns output" do
          expect(subject).to be_ok
        end
      end
    end
  end
end
