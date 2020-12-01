module RSpec
  module Mocks
    RSpec.describe ".allow_message" do
      let(:subject) { Object.new }

      it "sets up basic message allowance" do
        expect {
          ::RSpec::Mocks.allow_message(subject, :basic)
        }.to change {
          subject.respond_to?(:basic)
        }.to(true)

        expect(subject.basic).to eq(nil)
      end

      it "sets up message allowance with params and return value" do
        expect {
          ::RSpec::Mocks.allow_message(subject, :x).with(:in).and_return(:out)
        }.to change {
          subject.respond_to?(:x)
        }.to(true)

        expect(subject.x(:in)).to eq(:out)
      end

      it "supports block implementations" do
        ::RSpec::Mocks.allow_message(subject, :message) { :value }
        expect(subject.message).to eq(:value)
      end

      it "does not set an expectation that the message will be received" do
        ::RSpec::Mocks.allow_message(subject, :message)
        expect { verify subject }.not_to raise_error
      end

      it 'does not get confused when the string and symbol message form are both used' do
        ::RSpec::Mocks.allow_message(subject, :foo).with(1) { :a }
        ::RSpec::Mocks.allow_message(subject, "foo").with(2) { :b }

        expect(subject.foo(1)).to eq(:a)
        expect(subject.foo(2)).to eq(:b)

        reset subject
      end

      context 'when target cannot be proxied' do
        it 'raises ArgumentError with message' do
          expect { ::RSpec::Mocks.allow_message(:subject, :foo) { :a } }.to raise_error(ArgumentError)
        end
      end
    end

    RSpec.describe ".expect_message" do
      let(:subject) { Object.new }

      it "sets up basic message expectation, verifies as uncalled" do
        expect {
          ::RSpec::Mocks.expect_message(subject, :basic)
        }.to change {
          subject.respond_to?(:basic)
        }.to(true)

        expect { verify subject }.to fail
      end

      it "fails if never is specified and the message is called" do
        expect_fast_failure_from(subject, /expected.*0 times/) do
          ::RSpec::Mocks.expect_message(subject, :foo).never
          subject.foo
        end
      end

      it "sets up basic message expectation, verifies as called" do
        ::RSpec::Mocks.expect_message(subject, :basic)
        subject.basic
        verify subject
      end

      it "sets up message expectation with params and return value" do
        ::RSpec::Mocks.expect_message(subject, :msg).with(:in).and_return(:out)
        expect(subject.msg(:in)).to eq(:out)
        verify subject
      end

      it "accepts a block implementation for the expected message" do
        ::RSpec::Mocks.expect_message(subject, :msg) { :value }
        expect(subject.msg).to eq(:value)
        verify subject
      end

      it 'does not get confused when the string and symbol message form are both used' do
        ::RSpec::Mocks.expect_message(subject, :foo).with(1)
        ::RSpec::Mocks.expect_message(subject, "foo").with(2)

        subject.foo(1)
        subject.foo(2)

        verify subject
      end

      context 'when target cannot be proxied' do
        it 'raises ArgumentError with message' do
          expect { ::RSpec::Mocks.expect_message(:subject, :foo) { :a } }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
