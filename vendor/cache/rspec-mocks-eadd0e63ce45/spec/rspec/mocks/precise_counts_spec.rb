module RSpec
  module Mocks
    RSpec.describe "PreciseCounts" do
      before(:each) do
        @double = double("test double")
      end

      it "fails when exactly n times method is called less than n times" do
        expect(@double).to receive(:do_something).exactly(3).times
        @double.do_something
        @double.do_something
        expect {
          verify @double
        }.to fail
      end

      it "fails fast when exactly n times method is called more than n times" do
        expect(@double).to receive(:do_something).exactly(3).times
        @double.do_something
        @double.do_something
        @double.do_something
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when exactly n times method is never called" do
        expect(@double).to receive(:do_something).exactly(3).times
        expect {
          verify @double
        }.to fail
      end

      it "passes if exactly n times method is called exactly n times" do
        expect(@double).to receive(:do_something).exactly(3).times
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "returns the value given by a block when the exactly once method is called" do
        expect(@double).to receive(:to_s).exactly(:once) { "testing" }
        expect(@double.to_s).to eq "testing"
        verify @double
      end

      it "passes mutiple calls with different args" do
        expect(@double).to receive(:do_something).once.with(1)
        expect(@double).to receive(:do_something).once.with(2)
        @double.do_something(1)
        @double.do_something(2)
        verify @double
      end

      it "passes multiple calls with different args and counts" do
        expect(@double).to receive(:do_something).twice.with(1)
        expect(@double).to receive(:do_something).once.with(2)
        @double.do_something(1)
        @double.do_something(2)
        @double.do_something(1)
        verify @double
      end
    end
  end
end
