require "rails_helper"

RSpec.describe "User visits a homepage" do
  context "when no options specified" do
    let(:author) { create(:user, profile_image: nil) }
    let!(:article) { create(:article, reactions_count: 12, featured: true, user: author) }
    let!(:article2) { create(:article, reactions_count: 20, featured: true, user: author) }
    # Let's use yesterday's date for this instead of relying on a magic date.
    let(:published_datetime) { 1.day.ago.utc.change(hour: 10, min: 0, sec: 0) }
    let(:timestamp) { article.published_timestamp }
    let(:published_date) { article.readable_publish_date }

    context "when main featured article" do
      before do
        article.update_column(:published_at, published_datetime)
        article2.update_column(:published_at, published_datetime)
        visit "/"
      end

      # Regression test for https://github.com/forem/forem/pull/12724
      it "shows the main article, readable date and time, and hides zero comment count", :aggregate_failures do
        expect(page).to have_css(".crayons-story--featured", visible: :visible)
        expect(page).to have_css(".crayons-story--featured time", text: published_date)
        expect(page).to have_css(".crayons-story--featured time[datetime='#{timestamp}']")
        expect(page).to have_text("Add Comment")
        expect(page).to have_no_text("0 #{I18n.t('core.comment').downcase}s")

        article.update_column(:comments_count, 50)
        visit "/"
        expect(page).to have_text(/50\s*#{I18n.t('core.comment').downcase}s/)
      end
    end

    context "when all other articles" do
      before do
        article.update_columns(score: 15, published_at: published_datetime)
        article2.update_columns(score: 15, published_at: published_datetime)
        visit "/"
      end

      it "shows correct articles with their dates and times", :aggregate_failures do
        expect(page).to have_css(".crayons-story", count: 2)
        expect(page).to have_text(article.title)
        expect(page).to have_text(article2.title)
        expect(page).to have_css(".crayons-story time", text: published_date, count: 2)
        expect(page).to have_css(".crayons-story time[datetime='#{timestamp}']", count: 2)
      end
    end
  end

  describe "meta tags" do
    before { visit "/" }

    it "contains the qualified community name in og:title, og:site_name, and twitter:title", :aggregate_failures do
      expect(page).to have_css("meta[property='og:title'][content='#{community_name}']", visible: :hidden)
      expect(page).to have_css("meta[property='og:site_name'][content='#{community_name}']", visible: :hidden)
      expect(page).to have_css("meta[name='twitter:title'][content='#{community_name}']", visible: :hidden)
    end
  end
end
