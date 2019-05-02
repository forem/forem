require "rails_helper"

RSpec.describe Page, type: :model do
  let(:page)         { create(:page) }

  describe "#processed_html" do
    it "accepts body markdown and turns it into html" do
      page.body_markdown = "Hello `heyhey`"
      page.save
      expect(page.processed_html).to include("<code>")
    end

    it "accepts body html" do
      page.body_html = "Hello `heyhey`"
      page.body_markdown = nil
      page.save
      expect(page.processed_html).to eq(page.body_html)
    end

    it "requires either body_markdown or body_html" do
      page.body_html = nil
      page.body_markdown = nil
      expect(page).not_to be_valid
    end
  end
end
