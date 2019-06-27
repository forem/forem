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

    it "triggers cache busting on save" do
      expect { build(:page).save }.to have_enqueued_job.on_queue("pages_bust_cache")
    end
  end

  describe "#validations" do
    it "takes organization slug into account" do
      create(:organization, slug: "benandfriends")
      page = build(:page, slug: "benandfriends")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes podcast slug into account" do
      create(:podcast, slug: "benmeetsworld")
      page = build(:page, slug: "benmeetsworld")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes user username into account" do
      create(:user, username: "bennybenben")
      page = build(:page, slug: "bennybenben")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end
  end
end
