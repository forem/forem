# frozen_string_literal: true
# encoding: utf-8

require_relative "../../lib/slack-notifier"

ruby = if defined?(JRUBY_VERSION)
  "jruby #{JRUBY_VERSION}"
else
  "ruby #{RUBY_VERSION}"
end
puts "testing with #{ruby}"

notifier = Slack::Notifier.new ENV["SLACK_WEBHOOK_URL"], username: "notifier"
notifier.ping "hello", channel: ["#general", "#random"]
notifier.ping "hello/こんにちは from notifier test script on #{ruby}\225"
notifier.ping attachments: [{ color: "#1BF5AF", fallback: "fallback", text: "attachment" }]
