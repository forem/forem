module RSpec
  module Mocks
    RSpec.describe "#once" do
      before(:each) do
        @double = double
      end

      it "passes when called once" do
        expect(@double).to receive(:do_something).once
        @double.do_something
        verify @double
      end

      it "passes when called once with specified args" do
        expect(@double).to receive(:do_something).once.with("a", "b", "c")
        @double.do_something("a", "b", "c")
        verify @double
      end

      it "passes when called once with unspecified args" do
        expect(@double).to receive(:do_something).once
        @double.do_something("a", "b", "c")
        verify @double
      end

      it "fails when called with wrong args" do
        expect(@double).to receive(:do_something).once.with("a", "b", "c")
        expect {
          @double.do_something("d", "e", "f")
        }.to fail
        reset @double
      end

      it "fails fast when called twice" do
        expect(@double).to receive(:do_something).once
        @double.do_something
        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end

      it "fails when not called" do
        expect(@double).to receive(:do_something).once
        expect {
          verify @double
        }.to fail
      end

      context "when called with the wrong number of times with the specified args and also called with different args" do
        it "mentions the wrong call count in the failure message rather than the different args" do
          allow(@double).to receive(:do_something) # allow any args...
          expect(@double).to receive(:do_something).with(:args, 1).once

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
          }.to fail_with(a_string_including("expected: 1 time", "received: 2 times"))
        end
      end

      context "when called with negative expectation" do
        it "raises an error" do
          expect {
            expect(@double).not_to receive(:do_something).once
          }.to raise_error(/`count` is not supported with negative message expectations/)
        end
      end
    end
  end
end
