module RSpec
  module Mocks
    RSpec.describe "a message expectation with multiple invoke handlers and no specified count" do
      let(:a_double) { double }

      before(:each) do
        expect(a_double).to receive(:do_something).and_invoke(lambda { 1 }, lambda { raise "2" }, lambda { 3 })
      end

      it "invokes procs in order" do
        expect(a_double.do_something).to eq 1
        expect { a_double.do_something }.to raise_error("2")
        expect(a_double.do_something).to eq 3
        verify a_double
      end

      it "falls back to a previously stubbed value" do
        allow(a_double).to receive_messages :do_something => :stub_result
        expect(a_double.do_something).to eq 1
        expect { a_double.do_something }.to raise_error("2")
        expect(a_double.do_something).to eq 3
        expect(a_double.do_something).to eq :stub_result
      end

      it "fails when there are too few calls (if there is no stub)" do
        a_double.do_something
        expect { a_double.do_something }.to raise_error("2")
        expect { verify a_double }.to fail
      end

      it "fails when there are too many calls (if there is no stub)" do
        a_double.do_something
        expect { a_double.do_something }.to raise_error("2")
        a_double.do_something
        a_double.do_something
        expect { verify a_double }.to fail
      end
    end

    RSpec.describe "a message expectation with multiple invoke handlers with a specified count equal to the number of values" do
      let(:a_double) { double }

      before(:each) do
        expect(a_double).to receive(:do_something).exactly(3).times.and_invoke(lambda { 1 }, lambda { raise "2" }, lambda { 3 })
      end

      it "returns values in order to consecutive calls" do
        expect(a_double.do_something).to eq 1
        expect { a_double.do_something }.to raise_error("2")
        expect(a_double.do_something).to eq 3
        verify a_double
      end
    end

    RSpec.describe "a message expectation with multiple invoke handlers specifying at_least less than the number of values" do
      let(:a_double) { double }

      before { expect(a_double).to receive(:do_something).at_least(:twice).with(no_args).and_invoke(lambda { 11 }, lambda { 22 }) }

      it "uses the last return value for subsequent calls" do
        expect(a_double.do_something).to equal(11)
        expect(a_double.do_something).to equal(22)
        expect(a_double.do_something).to equal(22)
        verify a_double
      end

      it "fails when called less than the specified number" do
        expect(a_double.do_something).to equal(11)
        expect { verify a_double }.to fail
      end

      context "when method is stubbed too" do
        before { allow(a_double).to receive(:do_something).and_invoke lambda { :stub_result } }

        it "uses the last value for subsequent calls" do
          expect(a_double.do_something).to equal(11)
          expect(a_double.do_something).to equal(22)
          expect(a_double.do_something).to equal(22)
          verify a_double
        end

        it "fails when called less than the specified number" do
          expect(a_double.do_something).to equal(11)
          expect { verify a_double }.to fail
        end
      end
    end

    RSpec.describe "a message expectation with multiple invoke handlers with a specified count larger than the number of values" do
      let(:a_double) { double }
      before { expect(a_double).to receive(:do_something).exactly(3).times.and_invoke(lambda { 11 }, lambda { 22 }) }

      it "uses the last return value for subsequent calls" do
        expect(a_double.do_something).to equal(11)
        expect(a_double.do_something).to equal(22)
        expect(a_double.do_something).to equal(22)
        verify a_double
      end

      it "fails when called less than the specified number" do
        a_double.do_something
        a_double.do_something
        expect { verify a_double }.to fail
      end

      it "fails fast when called greater than the specified number" do
        a_double.do_something
        a_double.do_something
        a_double.do_something

        expect_fast_failure_from(a_double) do
          a_double.do_something
        end
      end
    end
  end
end
