require "rails_helper"

RSpec.describe Page, type: :model do
  describe "#validations" do
    xit "requires either body_markdown or body_html" do
      page = build(:page)
      page.body_html = nil
      page.body_markdown = nil
      expect(page).not_to be_valid
    end

    xit "takes organization slug into account" do
      create(:organization, slug: "benandfriends")
      page = build(:page, slug: "benandfriends")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    xit "takes podcast slug into account" do
      create(:podcast, slug: "benmeetsworld")
      page = build(:page, slug: "benmeetsworld")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    xit "takes user username into account" do
      create(:user, username: "bennybenben")
      page = build(:page, slug: "bennybenben")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end

    xit "takes sitemap into account" do
      page = build(:page, slug: "sitemap-hey")
      expect(page).not_to be_valid
      expect(page.errors[:slug].to_s.include?("taken")).to be true
    end
  end

  context "when callbacks are triggered before save" do
    let(:page) { create(:page) }

    describe "#processed_html" do
      xit "accepts body markdown and turns it into html" do
        page.update(body_markdown: "Hello `heyhey`")
        expect(page.processed_html).to include("<code>")
      end

      xit "accepts body html without changing it" do
        html = "Hello `heyhey`"
        page.update(body_html: html, body_markdown: "")
        expect(page.processed_html).to eq(html)
      end
    end
  end

  context "when callbacks are triggered after save" do
    let(:page) { create(:page) }

    xit "triggers cache busting on save" do
      sidekiq_assert_enqueued_with(job: Pages::BustCacheWorker, args: [page.slug]) do
        page.save
      end
    end
  end
end
