module RSpec
  module Mocks
    RSpec.shared_examples "complains when given blocks" do
      it "complains if a { } block is given" do
        expect {
          target.to receive_messages(:a => 1) { "implementation" }
        }.to raise_error "Implementation blocks aren't supported with `receive_messages`"
      end

      it "complains if a do; end; block is given" do
        expect {
          target.to receive_messages(:a => 1) do
            "implementation"
          end
        }.to raise_error "Implementation blocks aren't supported with `receive_messages`"
      end
    end

    RSpec.shared_examples "handles partially mocked objects correctly" do
      let(:obj) { Struct.new(:a).new('original') }

      it "resets partially mocked objects correctly" do
        target.to receive_messages(:a => 1, :b => 2)

        expect {
          reset obj
        }.to change { obj.a }.from(1).to("original")
      end
    end

    RSpec.describe "allow(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { double "Object" }
      let(:target) { allow(obj) }

      it "allows the object to respond to multiple messages" do
        allow(obj).to receive_messages(:a => 1, :b => 2)
        expect(obj.a).to eq 1
        expect(obj.b).to eq 2
      end

      it_behaves_like "complains when given blocks"
      it_behaves_like "handles partially mocked objects correctly"
    end

    RSpec.describe "allow_any_instance_of(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { Object.new }
      let(:target) { allow_any_instance_of(Object) }

      it "allows the object to respond to multiple messages" do
        allow_any_instance_of(Object).to receive_messages(:a => 1, :b => 2)
        expect(obj.a).to eq 1
        expect(obj.b).to eq 2
      end

      it "updates stubs on instances with existing stubs" do
        allow(obj).to receive(:a).and_return(3)
        expect(obj.a).to eq(3)

        allow_any_instance_of(Object).to receive_messages(:a => 1, :b => 2)
        expect(obj.a).to eq 1
        expect(obj.b).to eq 2
      end

      it_behaves_like "complains when given blocks"
    end

    RSpec.describe "expect(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { double "Object" }
      let(:target) { expect(obj) }

      let(:expectation_error) do
        failure = nil
        begin
          verify_all
        rescue RSpec::Mocks::MockExpectationError => error
          failure = error
        end
        failure
      end

      it "sets up multiple expectations" do
        expect(obj).to receive_messages(:a => 1, :b => 2)
        obj.a
        expect { verify_all }.to fail
      end

      it 'fails with a sensible message' do
        expect(obj).to receive_messages(:a => 1, :b => 2)
        obj.b
        expect(expectation_error.to_s).to eq %Q{(Double "Object").a(no args)\n    expected: 1 time with any arguments\n    received: 0 times}
      end

      it 'fails with the correct location' do
        expect(obj).to receive_messages(:a => 1, :b => 2); line = __LINE__
        expect(expectation_error.backtrace[0]).to match(/#{__FILE__}:#{line}/)
      end

      it_behaves_like "complains when given blocks"
      it_behaves_like "handles partially mocked objects correctly"

      it "provides a matcher description" do
        messages = { :a => 1, :b => 2 }
        matcher = receive_messages(messages)
        expect(matcher.description).to eq("receive messages: #{messages.inspect}")
      end
    end

    RSpec.describe "expect_any_instance_of(...).to receive_messages(:a => 1, :b => 2)" do
      let(:obj) { Object.new }
      let(:target) { expect_any_instance_of(Object) }

      it "sets up multiple expectations" do
        expect_any_instance_of(Object).to receive_messages(:a => 1, :b => 2)
        obj.a
        expect { RSpec::Mocks.space.verify_all }.to fail
        RSpec::Mocks.space.reset_all
      end

      it_behaves_like "complains when given blocks"
    end

    RSpec.describe "negative expectation failure" do
      let(:obj) { Object.new }

      example "allow(...).to_not receive_messages(:a => 1, :b => 2)" do
        expect { allow(obj).to_not receive_messages(:a => 1, :b => 2) }.to(
          raise_error "`allow(...).to_not receive_messages` is not supported " \
                      "since it doesn't really make sense. What would it even mean?"
        )
      end

      example "allow_any_instance_of(...).to_not receive_messages(:a => 1, :b => 2)" do
        expect { allow_any_instance_of(obj).to_not receive_messages(:a => 1, :b => 2) }.to(
          raise_error "`allow_any_instance_of(...).to_not receive_messages` is not supported " \
                      "since it doesn't really make sense. What would it even mean?"
        )
      end

      example "expect(...).to_not receive_messages(:a => 1, :b => 2)" do
        expect { expect(obj).to_not receive_messages(:a => 1, :b => 2) }.to(
          raise_error "`expect(...).to_not receive_messages` is not supported " \
                      "since it doesn't really make sense. What would it even mean?"
        )
      end

      example "expect_any_instance_of(...).to_not receive_messages(:a => 1, :b => 2)" do
        expect { expect_any_instance_of(obj).to_not receive_messages(:a => 1, :b => 2) }.to(
          raise_error "`expect_any_instance_of(...).to_not receive_messages` is not supported " \
                      "since it doesn't really make sense. What would it even mean?"
        )
      end
    end
  end
end
