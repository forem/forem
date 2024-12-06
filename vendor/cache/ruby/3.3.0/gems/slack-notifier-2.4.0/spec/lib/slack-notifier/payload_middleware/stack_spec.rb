# frozen_string_literal: true

RSpec.describe Slack::Notifier::PayloadMiddleware::Stack do
  let(:return_one) do
    double(call: 1)
  end

  let(:return_one_twice) do
    double(call: [1, 1])
  end

  let(:return_two) do
    double(call: 2)
  end

  let(:return_three) do
    double(call: 3)
  end

  before(:each) do
    # setup our middleware in the registry
    @registry_backup = Slack::Notifier::PayloadMiddleware.registry.dup
    Slack::Notifier::PayloadMiddleware.send(:remove_instance_variable, :@registry)

    Slack::Notifier::PayloadMiddleware.register return_one, :return_one
    Slack::Notifier::PayloadMiddleware.register return_one_twice, :return_one_twice
    Slack::Notifier::PayloadMiddleware.register return_two, :return_two
    Slack::Notifier::PayloadMiddleware.register return_three, :return_three
  end

  after(:each) do
    # cleanup middleware registry
    Slack::Notifier::PayloadMiddleware.send(:remove_instance_variable, :@registry)
    Slack::Notifier::PayloadMiddleware.send(:instance_variable_set, :@registry, @registry_backup)
  end

  describe "::initialize" do
    it "sets notifier to given notifier" do
      expect(described_class.new(:notifier).notifier).to eq :notifier
    end

    it "has empty stack" do
      expect(described_class.new(:notifier).stack).to match_array []
    end
  end

  describe "#set" do
    it "initializes each middleware w/ the notifier instance" do
      expect(return_one).to receive(:new).with(:notifier)
      expect(return_two).to receive(:new).with(:notifier)

      described_class.new(:notifier).set(:return_one, :return_two)
    end

    it "creates the stack in an array" do
      allow(return_one).to receive(:new).and_return(return_one)
      allow(return_two).to receive(:new).and_return(return_two)

      subject = described_class.new(:notifier)
      subject.set(:return_one, :return_two)

      expect(subject.stack).to be_a Array
      expect(subject.stack.first.call).to eq 1
      expect(subject.stack.last.call).to eq 2
    end

    it "creates a stack from hashes passing them as opts" do
      expect(return_one).to receive(:new).with(:notifier, opts: :for_one)
      expect(return_two).to receive(:new).with(:notifier, opts: :for_two)

      subject = described_class.new(:notifier)
      subject.set return_one: { opts: :for_one },
                  return_two: { opts: :for_two }
    end

    it "raises if a middleware is missing" do
      expect do
        described_class.new(:notifier).set(:missing)
      end.to raise_exception KeyError
    end
  end

  describe "#call" do
    it "calls the middleware in order, passing return of each to the next" do
      allow(return_one).to receive(:new).and_return(return_one)
      allow(return_two).to receive(:new).and_return(return_two)
      allow(return_three).to receive(:new).and_return(return_three)

      subject = described_class.new(:notifier)
      subject.set(:return_one, :return_three, :return_two)

      expect(return_one).to receive(:call).with(5)
      expect(return_three).to receive(:call).with(1)
      expect(return_two).to receive(:call).with(3)

      expect(subject.call(5)).to eq [2]
    end

    it "allows any middleware to return an array but other's don't need special behavior" do
      allow(return_one_twice).to receive(:new).and_return(return_one_twice)
      allow(return_two).to receive(:new).and_return(return_two)

      subject = described_class.new(:notifier)
      subject.set(:return_one_twice, :return_two)

      expect(subject.call(5)).to eq [2, 2]
    end

    it "handles multiple middleware splitting payload" do
      allow(return_one_twice).to receive(:new).and_return(return_one_twice)
      allow(return_two).to receive(:new).and_return(return_two)

      subject = described_class.new(:notifier)
      subject.set(:return_one_twice, :return_one_twice, :return_two)

      expect(subject.call(5)).to eq [2, 2, 2, 2]
    end
  end
end
