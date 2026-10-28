require "rails_helper"

RSpec.describe CommentEmailScrubber, type: :permit_scrubber do
  include ActionView::Helpers::SanitizeHelper

  def clean(html)
    sanitize(html, scrubber: described_class.new)
  end

  it "keeps allowed tags with children" do
    html = '<p>Hello <strong>world</strong> and <a href="https://dev.to">link</a></p>'
    expect(clean(html)).to eq(html)
  end

  it "removes script tags and their contents completely" do
    html = "<p>Hello</p><script>alert(1)</script>"
    output = clean(html)

    expect(output).to eq("<p>Hello</p>")
    expect(output).not_to include("<script")
    expect(output).not_to include("alert(1)")
  end
end
