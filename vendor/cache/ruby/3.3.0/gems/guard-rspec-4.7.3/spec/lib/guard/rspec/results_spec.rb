require "guard/compat/test/helper"

require "guard/rspec/results"

RSpec.describe Guard::RSpec::Results do
  subject do
    described_class.new("foo/bar.txt")
  end

  before do
    allow(File).to receive(:readlines).with("foo/bar.txt").and_return(data)
  end

  context "with valid data" do
    let(:data) do
      [
        "5 examples, 2 failures (3 pending)\n",
        "foo1/bar1_spec.rb\n",
        "foo1/bar2_spec.rb\n"
      ]
    end

    describe "#summary" do
      it "sets a summary" do
        expect(subject.summary).to eq("5 examples, 2 failures (3 pending)")
      end
    end

    describe "#failures" do
      it "sets a list of failures" do
        expect(subject.failed_paths).
          to eq(%w(foo1/bar1_spec.rb foo1/bar2_spec.rb))
      end
    end
  end

  context "with no data" do
    let(:data) do
      []
    end

    it "crashes" do
      expect do
        subject.load
      end.to raise_error(
        Guard::RSpec::Results::InvalidData,
        "Invalid results in: foo/bar.txt, lines:\n[]\n"
      )
    end
  end

  context "with invalid data" do
    let(:data) do
      [""]
    end

    it "crashes" do
      expect do
        subject.load
      end.to raise_error(
        Guard::RSpec::Results::InvalidData,
        "Invalid results in: foo/bar.txt, lines:\n[\"\"]\n"
      )
    end
  end
end
