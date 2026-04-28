require "rails_helper"

RSpec.describe ValidateUrl do
  let(:klass) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :feed_url

      validates :feed_url, feed_url: true
    end
  end

  it "accepts a valid Hashnode RSS feed" do
    valid_feed = <<~XML
      <?xml version="1.0" encoding="UTF-8" ?>
      <rss version="2.0">
        <channel>
          <title>Hashnode Blog</title>
          <link>https://example.hashnode.dev</link>
          <description>Example feed</description>
          <item>
            <title>My first post</title>
            <link>https://example.hashnode.dev/post-1</link>
            <description>Hello world</description>
          </item>
        </channel>
      </rss>
    XML

    allow(URI).to receive(:open).and_return(StringIO.new(valid_feed))

    record = klass.new(feed_url: "https://example.hashnode.dev/rss.xml")

    expect(record).to be_valid
  end
end