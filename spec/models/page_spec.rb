require "rails_helper"

RSpec.describe Page, type: :model do
  describe "#validations" do
    it "requires either body_markdown, body_html, or body_json" do
      page = build(:page)
      page.body_html = nil
      page.body_markdown = nil
      page.body_json = nil
      expect(page).not_to be_valid
    end

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

    it "takes sitemap into account" do
      page = build(:page, slug: "sitemap-hey")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    it "only allows a single landing_page to be set to true" do
      create(:page, landing_page: true)
      page = build(:page, landing_page: true)
      expect(page).not_to be_valid
      expect(page.errors[:base].to_s.include?("Only one page")).to be true
    end
  end

  context "when callbacks are triggered before save" do
    let(:page) { create(:page) }

    describe "#processed_html" do
      it "accepts body markdown and turns it into html" do
        page.update(body_markdown: "Hello `heyhey`")
        expect(page.processed_html).to include("<code>")
      end

      it "accepts body html without changing it" do
        html = "Hello `heyhey`"
        page.update(body_html: html, body_markdown: "")
        expect(page.processed_html).to eq(html)
      end
    end
  end

  context "when callbacks are triggered after save" do
    let(:page) { create(:page) }

    it "triggers cache busting on save" do
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: [page.slug]) do
        page.save
      end
    end
  end
end
