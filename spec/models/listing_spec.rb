require "rails_helper"

RSpec.describe Listing do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:listing) { create(:listing, user: user) }

  after { ActsAsTaggableOn.default_parser = ActsAsTaggableOn::DefaultParser }

  describe "body html" do
    it "converts markdown to html" do
      listing.body_markdown = "Test body"
      listing.save
      expect(listing.processed_html).to include("<p>Test body</p>")
    end

    it "parses away tag spaces" do
      listing.tag_list = "the best, tag list"
      listing.save
      expect(listing.tag_list).to eq(%w[thebest taglist])
    end
  end

  it "can be created with essential associations" do
     expect { create(:listing, user: user) }.not_to raise_error
  end
end