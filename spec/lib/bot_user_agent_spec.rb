require "rails_helper"

RSpec.describe BotUserAgent do
  it "matches a self-identified crawler" do
    expect(described_class.match?("Mozilla/5.0 (compatible; GPTBot/1.2)")).to be(true)
  end

  it "matches a crawler whose name lacks 'bot'" do
    expect(described_class.match?("Mozilla/5.0 (compatible; Bytespider; spider-feedback@bytedance.com)")).to be(true)
  end

  it "does not match a human browser user agent" do
    human_ua = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
               "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    expect(described_class.match?(human_ua)).to be(false)
  end

  it "does not match a blank user agent" do
    expect(described_class.match?(nil)).to be(false)
    expect(described_class.match?("")).to be(false)
  end
end
