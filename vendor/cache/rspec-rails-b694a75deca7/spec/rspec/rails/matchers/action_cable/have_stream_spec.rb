require "rspec/rails/feature_check"

if RSpec::Rails::FeatureCheck.has_action_cable_testing?
  class StreamModel < Struct.new(:id)
    def to_gid_param
      "StreamModel##{id}"
    end
  end

  class StreamChannel < ActionCable::Channel::Base
    def self.channel_name
      "broadcast"
    end

    def subscribed
      stream_from "chat_#{params[:id]}" if params[:id]
      stream_for StreamModel.new(params[:user]) if params[:user]
    end
  end
end

RSpec.describe "have_stream matchers", skip: !RSpec::Rails::FeatureCheck.has_action_cable_testing?  do
  include RSpec::Rails::ChannelExampleGroup

  tests StreamChannel if respond_to?(:tests)

  before { stub_connection }

  describe "have_streams" do
    it "raises when no subscription started" do
      expect {
        expect(subscription).to have_streams
      }.to raise_error(/Must be subscribed!/)
    end

    it "does not allow usage" do
      subscribe

      expect {
        expect(subscription).to have_streams
      }.to raise_error(ArgumentError, /have_streams is used for negated expectations only/)
    end

    context "with negated form" do
      it "raises when no subscription started" do
        expect {
          expect(subscription).not_to have_streams
        }.to raise_error(/Must be subscribed!/)
      end

      it "raises ArgumentError when no subscription passed to expect" do
        subscribe id: 1

        expect {
          expect(true).not_to have_streams
        }.to raise_error(ArgumentError)
      end

      it "passes with negated form" do
        subscribe

        expect(subscription).not_to have_streams
      end

      it "fails with message" do
        subscribe id: 1

        expect {
          expect(subscription).not_to have_streams
        }.to raise_error(/expected not to have any stream started/)
      end
    end
  end

  describe "have_stream_from" do
    it "raises when no subscription started" do
      expect {
        expect(subscription).to have_stream_from("stream")
      }.to raise_error(/Must be subscribed!/)
    end

    it "raises ArgumentError when no subscription passed to expect" do
      subscribe id: 1

      expect {
        expect(true).to have_stream_from("stream")
      }.to raise_error(ArgumentError)
    end

    it "passes" do
      subscribe id: 1

      expect(subscription).to have_stream_from("chat_1")
    end

    it "fails with message" do
      subscribe id: 1

      expect {
        expect(subscription).to have_stream_from("chat_2")
      }.to raise_error(/expected to have stream "chat_2" started, but have \[\"chat_1\"\]/)
    end

    context "with negated form" do
      it "passes" do
        subscribe id: 1

        expect(subscription).not_to have_stream_from("chat_2")
      end

      it "fails with message" do
        subscribe id: 1

        expect {
          expect(subscription).not_to have_stream_from("chat_1")
        }.to raise_error(/expected not to have stream "chat_1" started, but have \[\"chat_1\"\]/)
      end
    end

    context "with composable matcher" do
      it "passes" do
        subscribe id: 1

        expect(subscription).to have_stream_from(a_string_starting_with("chat"))
      end

      it "fails with message" do
        subscribe id: 1

        expect {
          expect(subscription).to have_stream_from(a_string_starting_with("room"))
        }.to raise_error(/expected to have stream a string starting with "room" started, but have \[\"chat_1\"\]/)
      end
    end
  end

  describe "have_stream_for" do
    it "raises when no subscription started" do
      expect {
        expect(subscription).to have_stream_for(StreamModel.new(42))
      }.to raise_error(/Must be subscribed!/)
    end

    it "raises ArgumentError when no subscription passed to expect" do
      subscribe user: 42

      expect {
        expect(true).to have_stream_for(StreamModel.new(42))
      }.to raise_error(ArgumentError)
    end

    it "passes" do
      subscribe user: 42

      expect(subscription).to have_stream_for(StreamModel.new(42))
    end

    it "fails with message" do
      subscribe user: 42

      expect {
        expect(subscription).to have_stream_for(StreamModel.new(31337))
      }.to raise_error(/expected to have stream "broadcast:StreamModel#31337" started, but have \[\"broadcast:StreamModel#42\"\]/)
    end

    context "with negated form" do
      it "passes" do
        subscribe user: 42

        expect(subscription).not_to have_stream_for(StreamModel.new(31337))
      end

      it "fails with message" do
        subscribe user: 42

        expect {
          expect(subscription).not_to have_stream_for(StreamModel.new(42))
        }.to raise_error(/expected not to have stream "broadcast:StreamModel#42" started, but have \[\"broadcast:StreamModel#42\"\]/)
      end
    end
  end
end
