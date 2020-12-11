module RSpec
  module Mocks
    RSpec.describe "A chained method stub" do
      let(:object) { Object.new }

      it 'does not get confused by symbol vs string usage for the messages' do
        allow(object).to receive_message_chain(:foo, :bar => 1)
        allow(object).to receive_message_chain("foo", :bazz => 2)

        expect(object.foo.bar).to eq(1)
        expect(object.foo.bazz).to eq(2)
      end

      context "with one method in chain" do
        context "using and_return" do
          it "returns expected value from chaining only one method call" do
            allow(object).to receive_message_chain(:msg1).and_return(:return_value)
            expect(object.msg1).to equal(:return_value)
          end
        end

        context "using a block" do
          it "returns the correct value" do
            allow(object).to receive_message_chain(:msg1) { :return_value }
            expect(object.msg1).to equal(:return_value)
          end
        end

        context "using a hash" do
          it "returns the value of the key/value pair" do
            allow(object).to receive_message_chain(:msg1 => :return_value)
            expect(object.msg1).to equal(:return_value)
          end
        end
      end

      context "with two methods in chain" do
        it "accepts any number of arguments to the stubbed messages in the chain" do
          allow(object).to receive_message_chain(:msg1, :msg2).and_return(:return_value)

          expect(object.msg1("nonsense", :value).msg2("another", :nonsense, 3.0, "value")).to eq(:return_value)
        end

        context "using and_return" do
          it "returns expected value from chaining two method calls" do
            allow(object).to receive_message_chain(:msg1, :msg2).and_return(:return_value)
            expect(object.msg1.msg2).to equal(:return_value)
          end
        end

        context "using a block" do
          it "returns the correct value" do
            allow(object).to receive_message_chain(:msg1, :msg2) { :return_value }
            expect(object.msg1.msg2).to equal(:return_value)
          end
        end

        context "using a hash" do
          it "returns the value of the key/value pair" do
            allow(object).to receive_message_chain(:msg1, :msg2 => :return_value)
            expect(object.msg1.msg2).to equal(:return_value)
          end
        end
      end

      context "with four methods in chain" do
        context "using and_return" do
          it "returns expected value from chaining two method calls" do
            allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg4).and_return(:return_value)
            expect(object.msg1.msg2.msg3.msg4).to equal(:return_value)
          end
        end

        context "using a block" do
          it "returns the correct value" do
            allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg4) { :return_value }
            expect(object.msg1.msg2.msg3.msg4).to equal(:return_value)
          end
        end

        context "using a hash" do
          it "returns the value of the key/value pair" do
            allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg4 => :return_value)
            expect(object.msg1.msg2.msg3.msg4).to equal(:return_value)
          end
        end

        context "using a hash with a string key" do
          it "returns the value of the key/value pair" do
            allow(object).to receive_message_chain("msg1.msg2.msg3.msg4" => :return_value)
            expect(object.msg1.msg2.msg3.msg4).to equal(:return_value)
          end
        end
      end

      it "returns expected value from chaining four method calls" do
        allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg4).and_return(:return_value)
        expect(object.msg1.msg2.msg3.msg4).to equal(:return_value)
      end

      context "with messages shared across multiple chains" do
        context "using and_return" do
          context "starting with the same message" do
            it "returns expected value" do
              allow(object).to receive_message_chain(:msg1, :msg2, :msg3).and_return(:first)
              allow(object).to receive_message_chain(:msg1, :msg2, :msg4).and_return(:second)

              expect(object.msg1.msg2.msg3).to equal(:first)
              expect(object.msg1.msg2.msg4).to equal(:second)
            end
          end

          context "starting with the different messages" do
            it "returns expected value" do
              allow(object).to receive_message_chain(:msg1, :msg2, :msg3).and_return(:first)
              allow(object).to receive_message_chain(:msg4, :msg2, :msg3).and_return(:second)

              expect(object.msg1.msg2.msg3).to equal(:first)
              expect(object.msg4.msg2.msg3).to equal(:second)
            end
          end
        end

        context "using => value" do
          context "starting with the same message" do
            it "returns expected value" do
              allow(object).to receive_message_chain(:msg1, :msg2, :msg3 => :first)
              allow(object).to receive_message_chain(:msg1, :msg2, :msg4 => :second)

              expect(object.msg1.msg2.msg3).to equal(:first)
              expect(object.msg1.msg2.msg4).to equal(:second)
            end
          end

          context "starting with different messages" do
            it "returns expected value" do
              allow(object).to receive_message_chain(:msg1, :msg2, :msg3 => :first)
              allow(object).to receive_message_chain(:msg4, :msg2, :msg3 => :second)

              expect(object.msg1.msg2.msg3).to equal(:first)
              expect(object.msg4.msg2.msg3).to equal(:second)
            end
          end
        end
      end

      it "returns expected value when chain is a dot separated string, like stub_chain('msg1.msg2.msg3')" do
        allow(object).to receive_message_chain("msg1.msg2.msg3").and_return(:return_value)
        expect(object.msg1.msg2.msg3).to equal(:return_value)
      end

      it "returns expected value from two chains with shared messages at the beginning" do
        allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg4).and_return(:first)
        allow(object).to receive_message_chain(:msg1, :msg2, :msg3, :msg5).and_return(:second)

        expect(object.msg1.msg2.msg3.msg4).to equal(:first)
        expect(object.msg1.msg2.msg3.msg5).to equal(:second)
      end

      it "handles private instance methods (like Object#select) in the middle of a chain" do
        allow(object).to receive_message_chain(:msg1, :select, :msg3 => 'answer')
        expect(object.msg1.select.msg3).to eq 'answer'
      end
    end
  end
end
