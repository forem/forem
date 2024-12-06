# frozen_string_literal: true

RSpec.describe Slack::Notifier::Config do
  describe "#http_client" do
    it "is Util::HTTPClient if not set" do
      subject = described_class.new
      expect(subject.http_client).to eq Slack::Notifier::Util::HTTPClient
    end

    it "sets a new client class if given one" do
      new_client = class_double("Slack::Notifier::Util::HTTPClient", post: nil)
      subject    = described_class.new
      subject.http_client new_client
      expect(subject.http_client).to eq new_client
    end

    it "raises an ArgumentError if given class does not respond to ::post" do
      subject = described_class.new
      expect do
        subject.http_client :nope
      end.to raise_error ArgumentError
    end
  end

  describe "#defaults" do
    it "is an empty hash by default" do
      subject = described_class.new
      expect(subject.defaults).to eq({})
    end

    it "sets a hash to default if given" do
      subject = described_class.new
      subject.defaults foo: :bar
      expect(subject.defaults).to eq foo: :bar
    end

    it "raises ArgumentError if not given a hash" do
      subject = described_class.new
      expect do
        subject.defaults :nope
      end.to raise_error ArgumentError
    end
  end

  describe "#middleware" do
    it "is [:format_message, :format_attachments, :at] if not set" do
      subject = described_class.new

      expect(subject.middleware).to eq %i[format_message format_attachments at channels]
    end

    it "takes an array or a splat of args" do
      subject = described_class.new

      subject.middleware :layer, :two
      expect(subject.middleware).to eq %i[layer two]

      subject.middleware %i[one layer]
      expect(subject.middleware).to eq %i[one layer]
    end

    it "allows passing options to middleware stack" do
      subject = described_class.new
      subject.middleware one: { opts: :for_one },
                         two: { opts: :for_two }

      expect(subject.middleware).to eq one: { opts: :for_one },
                                       two: { opts: :for_two }
    end
  end
end
