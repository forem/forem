module RSpec
  module Mocks
    RSpec.describe "at_least" do
      before(:each) { @double = double }

      it "fails if method is never called" do
        expect(@double).to receive(:do_something).at_least(4).times
        expect {
          verify @double
        }.to raise_error(/expected: at least 4 times.*received: 0 times/m)
      end

      it "fails when called less than n times" do
        expect(@double).to receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        expect {
          verify @double
        }.to raise_error(/expected: at least 4 times.*received: 3 times/m)
      end

      it "fails when at least once method is never called" do
        expect(@double).to receive(:do_something).at_least(:once)
        expect {
          verify @double
        }.to raise_error(/expected: at least 1 time.*received: 0 times/m)
      end

      it "fails when at least twice method is called once" do
        expect(@double).to receive(:do_something).at_least(:twice)
        @double.do_something
        expect {
          verify @double
        }.to raise_error(/expected: at least 2 times.*received: 1 time/m)
      end

      it "fails when at least twice method is never called" do
        expect(@double).to receive(:do_something).at_least(:twice)
        expect {
          verify @double
        }.to raise_error(/expected: at least 2 times.*received: 0 times/m)
      end

      it "fails when at least thrice method is called less than three times" do
        expect(@double).to receive(:do_something).at_least(:thrice)
        @double.do_something
        @double.do_something
        expect {
          verify @double
        }.to raise_error(/expected: at least 3 times.*received: 2 times/m)
      end

      it "passes when at least n times method is called exactly n times" do
        expect(@double).to receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least n times method is called n plus 1 times" do
        expect(@double).to receive(:do_something).at_least(4).times
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least once method is called once" do
        expect(@double).to receive(:do_something).at_least(:once)
        @double.do_something
        verify @double
      end

      it "passes when at least once method is called twice" do
        expect(@double).to receive(:do_something).at_least(:once)
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least twice method is called three times" do
        expect(@double).to receive(:do_something).at_least(:twice)
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least twice method is called twice" do
        expect(@double).to receive(:do_something).at_least(:twice)
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least thrice method is called three times" do
        expect(@double).to receive(:do_something).at_least(:thrice)
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "passes when at least thrice method is called four times" do
        expect(@double).to receive(:do_something).at_least(:thrice)
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        verify @double
      end

      it "returns the value given by a block when the at least once method is called" do
        expect(@double).to receive(:to_s).at_least(:once) { "testing" }
        expect(@double.to_s).to eq "testing"
        verify @double
      end

      context "when sent with 0" do
        it "outputs a removal message" do
          expect {
            expect(@double).to receive(:do_something).at_least(0).times
          }.to raise_error(/has been removed/)
        end
      end

      it "uses a stub value if no value set" do
        allow(@double).to receive_messages(:do_something => 'foo')
        expect(@double).to receive(:do_something).at_least(:once)
        expect(@double.do_something).to eq 'foo'
        expect(@double.do_something).to eq 'foo'
      end

      it "prefers its own return value over a stub" do
        allow(@double).to receive_messages(:do_something => 'foo')
        expect(@double).to receive(:do_something).at_least(:once).and_return('bar')
        expect(@double.do_something).to eq 'bar'
        expect(@double.do_something).to eq 'bar'
      end

      context "when called with negative expectation" do
        it "raises an error" do
          expect {
            expect(@double).not_to receive(:do_something).at_least(:thrice)
          }.to raise_error(/`count` is not supported with negative message expectations/)
        end
      end
    end
  end
end
