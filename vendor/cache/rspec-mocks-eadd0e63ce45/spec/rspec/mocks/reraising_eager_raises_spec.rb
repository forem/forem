require "spec_helper"

RSpec.describe "Reraising eager raises during the verify step" do
  it "does not reraise when a double receives a message that hasn't been allowed/expected" do
    with_unfulfilled_double do |dbl|
      expect { dbl.foo }.to fail
      expect { verify_all }.not_to raise_error
    end
  end

  context "when a negative expectation receives a call" do
    it "reraises during verification" do
      with_unfulfilled_double do |dbl|
        expect(dbl).not_to receive(:foo)
        expect { dbl.foo }.to fail
        expect { verify_all }.to fail_with(/expected: 0 times with any arguments/)
      end
    end

    it 'notifies both exceptions using the same `:source_id` so `aggregate_failures` can de-dup' do
      with_unfulfilled_double do |dbl|
        expect(dbl).not_to receive(:foo)
        expect { dbl.foo }.to notify_with_same_source_id_as_later_verification
      end
    end

    it 'notifies with a different `source_id` than that for the same double and a different message' do
      with_unfulfilled_double do |dbl|
        expect(dbl).not_to receive(:foo)

        expect {
          dbl.foo # should trigger first source_id
          reset(dbl)

          # Prepare a failing expectation for a different message
          expect(dbl).not_to receive(:bar)
          RSpec::Support.with_failure_notifier(Proc.new {}) { dbl.bar }
        }.not_to notify_with_same_source_id_as_later_verification
      end
    end

    it 'notifies with a different `source_id` than a different double expecting that message' do
      with_unfulfilled_double do |dbl_1|
        with_unfulfilled_double do |dbl_2|
          expect(dbl_1).not_to receive(:foo)
          expect(dbl_2).not_to receive(:foo)

          expect { dbl_2.foo }.to fail
          expect { dbl_1.foo; reset(dbl_1) }.not_to notify_with_same_source_id_as_later_verification
        end
      end
    end
  end

  context "when an expectation with a count is exceeded" do
    def prepare(dbl)
      expect(dbl).to receive(:foo).exactly(2).times

      dbl.foo
      dbl.foo
    end

    it "reraises during verification" do
      with_unfulfilled_double do |dbl|
        prepare dbl

        expect { dbl.foo }.to fail
        expect { verify_all }.to fail_with(/expected: 2 times with any arguments/)
      end
    end

    it 'notifies both exceptions using the same `:source_id` so `aggregate_failures` can de-dup' do
      with_unfulfilled_double do |dbl|
        prepare dbl
        expect { dbl.foo }.to notify_with_same_source_id_as_later_verification
      end
    end
  end

  context "when an expectation is called with the wrong arguments" do
    it "reraises during verification" do
      with_unfulfilled_double do |dbl|
        expect(dbl).to receive(:foo).with(1, 2, 3)
        expect { dbl.foo(1, 2, 4) }.to fail
        expect { verify_all }.to fail_with(/expected: 1 time with arguments: \(1, 2, 3\)/)
      end
    end

    it 'notifies both exceptions using the same `:source_id` so `aggregate_failures` can de-dup' do
      with_unfulfilled_double do |dbl|
        expect(dbl).to receive(:foo).with(1, 2, 3)
        expect { dbl.foo(1, 2, 4) }.to notify_with_same_source_id_as_later_verification
      end
    end
  end

  context "when an expectation is called out of order",
          :pending => "Says bar was called 0 times when it was, see: http://git.io/pjTq" do
    it "reraises during verification" do
      with_unfulfilled_double do |dbl|
        expect(dbl).to receive(:foo).ordered
        expect(dbl).to receive(:bar).ordered
        expect { dbl.bar }.to fail
        dbl.foo # satisfy the `foo` expectation so that only the bar one fails below
        expect { verify_all }.to fail_with(/received :bar out of order/)
      end
    end
  end

  RSpec::Matchers.define :notify_with_same_source_id_as_later_verification do
    attr_reader :block

    match do |block|
      @block = block
      block_source_id == verify_all_source_id && block_source_id
    end

    match_when_negated do |block|
      @block = block
      block_source_id && verify_all_source_id && (
        block_source_id != verify_all_source_id
      )
    end

    supports_block_expectations

    failure_message do
      if block_source_id.nil?
        "expected it to notify with a non-nil source id"
      else
        "expected `verify_all` to notify with source_id: #{block_source_id.inspect} but notified with source_id: #{verify_all_source_id.inspect}"
      end
    end

    failure_message_when_negated do
      if block_source_id.nil?
        "expected it to notify with a non-nil source id"
      else
        "expected `verify_all` to notify with a different source_id but got the same one: #{block_source_id.inspect} / #{verify_all_source_id.inspect}"
      end
    end

    def block_source_id
      @block_source_id ||= capture_notified_source_id(&block)
    end

    def verify_all_source_id
      @verify_all_source_id ||= capture_notified_source_id { verify_all }
    end

    def capture_notified_source_id(&block)
      source_id = nil
      notifier = Proc.new { |_err, opt| source_id = opt.fetch(:source_id) }
      RSpec::Support.with_failure_notifier(notifier, &block)
      source_id
    end
  end
end
