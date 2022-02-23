require "rails_helper"

RSpec.describe FeedMarkdownScrubber, type: :permit_scrubber do
  include ActionView::Helpers::SanitizeHelper

  it "allows the tags specified by MarkdownProcessor" do
    good_html = <<~HTML
      <p>This is some <em>darn good</em> HTML right here.
      and <b>definitely</b> not in need of any:</p>
      <ul>
        <li>scrubbing</li>
        <li>cleaning</li>
        <li><a href="www.google.com">Tricky business.</a></li>
      </ul>
      <p>Even <span class="awesome">spans</span> make it through!</p>
    HTML
    clean = sanitize(good_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "scrubs out tags not allowed by MarkdownProcessor" do
    bad_html = "<p>Hello world!</p><form>Boo forms!</form>"
    good_html = "<p>Hello world!</p>Boo forms!"
    clean = sanitize(bad_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "allows attributes allowed by MarkdownProcessor" do
    good_html = <<~HTML
      <a id="linky-image" class="profile" href="www.google.com">
        <img src="www.example.com/fish.jpg" alt="An actual fish">
      </a>
    HTML
    clean = sanitize(good_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "scrubs out attributes not allowed by MarkdownProcessor" do
    bad_html = '<span name="jerry">Hi, I am Jerry.</span>'
    good_html = "<span>Hi, I am Jerry.</span>"
    clean = sanitize(bad_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "allows links in 'a' tags as long as they're not strictly relative links" do
    good_html = <<~HTML
      <a href="https://www.google.com">Link 1</a>
      <a href="https://www.google.com#title">Link 2</a>
    HTML
    clean = sanitize(good_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "scrubs relative links" do
    bad_html = '<a href="#relative"><h1>I link to somewhere on this page!</h1></a>'
    good_html = "<h1>I link to somewhere on this page!</h1>"
    clean = sanitize(bad_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end

  it "does not scrub anchors with no link" do
    good_html = "I put an anchor <a>here</a>"
    clean = sanitize(good_html, scrubber: described_class.new)
    expect(clean).to eq(good_html)
  end
end
