module RSpec
  module Mocks
    RSpec.describe "#twice" do
      before(:each) do
        @double = double("test double")
      end

      it "passes when called twice" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when called twice with specified args" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        @double.do_something("1", 1)
        @double.do_something("1", 1)
        verify @double
      end

      it "passes when called twice with unspecified args" do
        expect(@double).to receive(:do_something).twice
        @double.do_something("1")
        @double.do_something(1)
        verify @double
      end

      it "fails fast when call count is higher than expected" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        @double.do_something
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when call count is lower than expected" do
        expect(@double).to receive(:do_something).twice
        @double.do_something
        expect {
          verify @double
        }.to fail
      end

      it "fails when called with wrong args on the first call" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to fail
        reset @double
      end

      it "fails when called with wrong args on the second call" do
        expect(@double).to receive(:do_something).twice.with("1", 1)
        @double.do_something("1", 1)
        expect {
          @double.do_something(1, "1")
        }.to fail
        reset @double
      end

      context "when called with the wrong number of times with the specified args and also called with different args" do
        it "mentions the wrong call count in the failure message rather than the different args" do
          allow(@double).to receive(:do_something) # allow any args...
          expect(@double).to receive(:do_something).with(:args, 1).twice

          @double.do_something(:args, 2)
          @double.do_something(:args, 1)
          @double.do_something(:args, 2)
          @double.do_something(:args, 1)

          expect {
            # we've grouped these lines because it should probably fail fast
            # on the first line (since our expectation above only allows one
            # call with these args), but currently it fails with a confusing
            # message on verification, and ultimately we care more about
            # what the message is than when it is raised. Still, it would be
            # preferrable for the error to be triggered on the first line,
            # so it'd be good to update this spec to enforce that once we
            # get the failure message right.
            @double.do_something(:args, 1)
            verify @double
          }.to fail_with(a_string_including("expected: 2 times", "received: 3 times"))
        end
      end

      context "when called with negative expectation" do
        it "raises an error" do
          expect {
            expect(@double).not_to receive(:do_something).twice
          }.to raise_error(/`count` is not supported with negative message expectations/)
        end
      end
    end
  end
end
