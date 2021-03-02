module RSpec
  module Mocks
    RSpec.describe "#thrice" do
      before(:each) do
        @double = double("test double")
      end

      it "passes when called thrice" do
        expect(@double).to receive(:do_something).thrice
        3.times { @double.do_something }
        verify @double
      end

      it "passes when called thrice with specified args" do
        expect(@double).to receive(:do_something).thrice.with("1", 1)
        3.times { @double.do_something("1", 1) }
        verify @double
      end

      it "passes when called thrice with unspecified args" do
        expect(@double).to receive(:do_something).thrice
        @double.do_something("1")
        @double.do_something(1)
        @double.do_something(nil)
        verify @double
      end

      it "fails fast when call count is higher than expected" do
        expect(@double).to receive(:do_something).thrice
        3.times { @double.do_something }
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when call count is lower than expected" do
        expect(@double).to receive(:do_something).thrice
        @double.do_something
        expect {
          verify @double
        }.to fail
      end

      it "fails when called with wrong args on the first call" do
        expect(@double).to receive(:do_something).thrice.with("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to fail
        reset @double
      end

      it "fails when called with wrong args on the second call" do
        expect(@double).to receive(:do_something).thrice.with("1", 1)
        @double.do_something("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to fail
        reset @double
      end

      it "fails when called with wrong args on the third call" do
        expect(@double).to receive(:do_something).thrice.with("1", 1)
        @double.do_something("1", 1)
        @double.do_something("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to fail
        reset @double
      end

      context "when called with negative expectation" do
        it "raises an error" do
          expect {
            expect(@double).not_to receive(:do_something).thrice
          }.to raise_error(/`count` is not supported with negative message expectations/)
        end
      end
    end
  end
end
