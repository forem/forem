# frozen_string_literal: true

RSpec.describe Slack::Notifier::PayloadMiddleware::Base do
  before(:each) do
    @registry_backup = Slack::Notifier::PayloadMiddleware.registry.dup
    Slack::Notifier::PayloadMiddleware.send(:remove_instance_variable, :@registry)
  end

  after(:each) do
    # cleanup middleware registry
    Slack::Notifier::PayloadMiddleware.registry
    Slack::Notifier::PayloadMiddleware.send(:remove_instance_variable, :@registry)

    # cleanup object constants
    Object.send(:remove_const, :Subject) if Object.constants.include?(:Subject)
    Slack::Notifier::PayloadMiddleware.send(:instance_variable_set, :@registry, @registry_backup)
  end

  describe "::middleware_name" do
    it "registers class w/ given name" do
      class Subject < Slack::Notifier::PayloadMiddleware::Base
      end

      expect(Slack::Notifier::PayloadMiddleware)
        .to receive(:register).with(Subject, :subject)

      class Subject
        middleware_name :subject
      end
    end

    it "uses symbolized name to register" do
      class Subject < Slack::Notifier::PayloadMiddleware::Base
      end

      expect(Slack::Notifier::PayloadMiddleware)
        .to receive(:register).with(Subject, :subject)

      class Subject
        middleware_name "subject"
      end
    end
  end

  describe "::options" do
    it "allows setting default options for a middleware" do
      class Subject < Slack::Notifier::PayloadMiddleware::Base
        options foo: :bar
      end

      subject = Subject.new(:notifier)
      expect(subject.options).to eq foo: :bar

      subject = Subject.new(:notifier, foo: :baz)
      expect(subject.options).to eq foo: :baz
    end
  end

  describe "#initialize" do
    it "sets given notifier as notifier" do
      expect(described_class.new(:notifier).notifier).to eq :notifier
    end

    it "sets given options as opts" do
      expect(described_class.new(:notifier, opts: :options).options).to eq opts: :options
    end
  end

  describe "#call" do
    it "raises NoMethodError (expects subclass to define)" do
      expect do
        described_class.new(:notifier).call
      end.to raise_exception NoMethodError
    end
  end
end
