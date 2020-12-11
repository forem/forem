module RSpec
  module Mocks
    RSpec.describe "a double stubbed with multiple return values" do
      let(:a_double) { double }

      before do
        allow(a_double).to receive(:foo).and_return(:val_1, nil)
      end

      it 'can still set a message expectation with a single return value' do
        expect(a_double).to receive(:foo).once.and_return(:val_1)
        expect(a_double.foo).to eq(:val_1)
      end
    end

    RSpec.describe "a message expectation with multiple return values and no specified count" do
      before(:each) do
        @double = double
        @return_values = [1, 2, 3]
        expect(@double).to receive(:do_something).and_return(@return_values[0], @return_values[1], @return_values[2])
      end

      it "returns values in order" do
        expect(@double.do_something).to eq @return_values[0]
        expect(@double.do_something).to eq @return_values[1]
        expect(@double.do_something).to eq @return_values[2]
        verify @double
      end

      it "falls back to a previously stubbed value" do
        allow(@double).to receive_messages :do_something => :stub_result
        expect(@double.do_something).to eq @return_values[0]
        expect(@double.do_something).to eq @return_values[1]
        expect(@double.do_something).to eq @return_values[2]
        expect(@double.do_something).to eq :stub_result
      end

      it "fails when there are too few calls (if there is no stub)" do
        @double.do_something
        @double.do_something
        expect { verify @double }.to fail
      end

      it "fails when there are too many calls (if there is no stub)" do
        @double.do_something
        @double.do_something
        @double.do_something
        @double.do_something
        expect { verify @double }.to fail
      end
    end

    RSpec.describe "a message expectation with multiple return values with a specified count equal to the number of values" do
      before(:each) do
        @double = double
        @return_values = [1, 2, 3]
        expect(@double).to receive(:do_something).exactly(3).times.and_return(@return_values[0], @return_values[1], @return_values[2])
      end

      it "returns values in order to consecutive calls" do
        expect(@double.do_something).to eq @return_values[0]
        expect(@double.do_something).to eq @return_values[1]
        expect(@double.do_something).to eq @return_values[2]
        verify @double
      end
    end

    RSpec.describe "a message expectation with multiple return values specifying at_least less than the number of values" do
      before(:each) do
        @double = double
        expect(@double).to receive(:do_something).at_least(:twice).with(no_args).and_return(11, 22)
      end

      it "uses the last return value for subsequent calls" do
        expect(@double.do_something).to equal(11)
        expect(@double.do_something).to equal(22)
        expect(@double.do_something).to equal(22)
        verify @double
      end

      it "fails when called less than the specified number" do
        expect(@double.do_something).to equal(11)
        expect { verify @double }.to fail
      end

      context "when method is stubbed too" do
        before { allow(@double).to receive(:do_something).and_return :stub_result }

        it "uses the last value for subsequent calls" do
          expect(@double.do_something).to equal(11)
          expect(@double.do_something).to equal(22)
          expect(@double.do_something).to equal(22)
          verify @double
        end

        it "fails when called less than the specified number" do
          expect(@double.do_something).to equal(11)
          expect { verify @double }.to fail
        end
      end
    end

    RSpec.describe "a message expectation with multiple return values with a specified count larger than the number of values" do
      before(:each) do
        @double = RSpec::Mocks::Double.new("double")
        expect(@double).to receive(:do_something).exactly(3).times.and_return(11, 22)
      end

      it "uses the last return value for subsequent calls" do
        expect(@double.do_something).to equal(11)
        expect(@double.do_something).to equal(22)
        expect(@double.do_something).to equal(22)
        verify @double
      end

      it "fails when called less than the specified number" do
        @double.do_something
        @double.do_something
        expect { verify @double }.to fail
      end

      it "fails fast when called greater than the specified number" do
        @double.do_something
        @double.do_something
        @double.do_something

        expect_fast_failure_from(@double) do
          @double.do_something
        end
      end
    end
  end
end
