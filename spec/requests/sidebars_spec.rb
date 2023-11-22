require "rails_helper"

RSpec.describe "Sidebars" do
  describe "GET /sidebars/home" do
    it "includes relevant parts" do
      listing = create(:listing, published: true)
      create(:tag, name: "rubymagoo")
      allow(Settings::General).to receive(:sidebar_tags).and_return(["rubymagoo"])
      get "/sidebars/home"
      expect(response.body).to include("rubymagoo")
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end

    context "when active discussions exist" do
      let(:tag) { create(:tag, name: "testmagoo") }
      let(:user) { create(:user) }
      let!(:article) do
        create(:article, tag_list: tag.name, last_comment_at: 1.day.ago, language: "en",
                         score: 10, comments_count: 5, created_at: 3.days.ago)
      end

      before do
        user.follow(tag)
      end

      it "does not include active article if not signed in" do
        get "/sidebars/home"
        expect(response.body).not_to include("active-discussions")
      end

      it "does show active discussions if signed in and user follows tag" do
        sign_in user
        get "/sidebars/home"
        expect(response.body).to include(CGI.escapeHTML(article.title))
      end

      it "includes an article without the proper tags if featured" do
        second_article = create(:article, featured: true)
        sign_in user
        get "/sidebars/home"
        expect(response.body).to include(CGI.escapeHTML(second_article.title))
      end

      it "does not include non-featured non-tagg-followed article" do
        second_article = create(:article, language: "en")
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include(CGI.escapeHTML(second_article.title))
      end
    end
  end
end
