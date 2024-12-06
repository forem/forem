# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

RSpec.describe Slack::Notifier do
  {
    { text: "hello" } =>
    { payload: { text: "hello" } },

    { text: "[hello](http://example.com/world)" } =>
    { payload: { text: "<http://example.com/world|hello>" } },

    { text: '<a href="http://example.com">example</a>' } =>
    { payload: { text: "<http://example.com|example>" } },

    { text: "hello/こんにちは from notifier test" } =>
    { payload: { text: "hello/こんにちは from notifier test" } },

    { text: "Hello World, enjoy [](http://example.com)." } =>
    { payload: { text: "Hello World, enjoy <http://example.com>." } },

    { text: "Hello World, enjoy [this](http://example.com)[this2](http://example2.com)" } =>
    { payload: { text: "Hello World, enjoy <http://example.com|this><http://example2.com|this2>" } },

    { text: "[John](mailto:john@example.com)" } =>
    { payload: { text: "<mailto:john@example.com|John>" } },

    { text: '<a href="mailto:john@example.com">John</a>' } =>
    { payload: { text: "<mailto:john@example.com|John>" } },

    { text: "hello", channel: "hodor" } =>
    { payload: { text: "hello", channel: "hodor" } },

    { text: nil, attachments: [{ text: "attachment message" }] } =>
    { payload: { text: nil, attachments: [{ text: "attachment message" }] } },

    { text: "the message", channel: "foo", attachments: [{ color: "#000",
                                                           text: "attachment message",
                                                           fallback: "fallback message" }] } =>
    { payload: { text: "the message",
                 channel: "foo",
                 attachments: [{ color: "#000",
                                 text: "attachment message",
                                 fallback: "fallback message" }] } },

    { attachments: [{ color: "#000",
                      text: "attachment message",
                      fallback: "fallback message" }] } =>
    { payload: { attachments: [{ color: "#000",
                                 text: "attachment message",
                                 fallback: "fallback message" }] } },

    { attachments: { color: "#000",
                     text: "attachment message [hodor](http://winterfell.com)",
                     fallback: "fallback message" } } =>
    { payload: { attachments: [{ color: "#000",
                                 text: "attachment message <http://winterfell.com|hodor>",
                                 fallback: "fallback message" }] } },

    { attachments: { color: "#000",
                     text: nil,
                     fallback: "fallback message" } } =>
    { payload: { attachments: [{ color: "#000",
                                 text: nil,
                                 fallback: "fallback message" }] } },

    { text: "hello", http_options: { timeout: 5 } } =>
    { http_options: { timeout: 5 }, payload: { text: "hello" } }
  }.each do |args, payload|
    it "sends correct payload for #post(#{args})" do
      http_client       = class_double("Slack::Notifier::Util::HTTPClient", post: nil)
      notifier          = Slack::Notifier.new "http://example.com", http_client: http_client
      payload[:payload] = payload[:payload].to_json

      expect(http_client).to receive(:post)
        .with(URI.parse("http://example.com"), payload)

      notifier.post(args)
    end
  end

  it "applies options given to middleware" do
    client   = class_double("Slack::Notifier::Util::HTTPClient", post: nil)
    notifier = Slack::Notifier.new "http://example.com" do
      http_client client
      middleware format_message: { formats: [] }
    end

    expect(client).to receive(:post)
      .with(URI.parse("http://example.com"), payload: { text: "Hello [world](http://example.com)!" }.to_json)

    notifier.post text: "Hello [world](http://example.com)!"
  end
end
