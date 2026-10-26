# spec/views/articles/_single_story.html.erb_spec.rb

require "rails_helper"

RSpec.describe "articles/_single_story.html.erb", type: :view do
  let(:author) { create(:user) }
  let(:article) { create(:article, user: author) }
  let(:story) { article.decorate }

  context "when user is signed in" do
    let(:current_user) { create(:user) }

    before do
      allow(view).to receive(:user_signed_in?).and_return(true)
      allow(view).to receive(:current_user).and_return(current_user)
      assign(:user, current_user)
    end

    it "renders the bookmark button when is_home_feed is true" do
      render partial: "articles/single_story", locals: { story: story, is_home_feed: true, featured: false, feed_style_preference: "basic" }

      expect(rendered).to have_css("#article-save-button-#{story.id}")
      expect(rendered).to have_css(".bookmark-button")
    end

    it "does not render the bookmark button when is_home_feed is false" do
      render partial: "articles/single_story", locals: { story: story, is_home_feed: false, featured: false, feed_style_preference: "basic" }

      expect(rendered).not_to have_css("#article-save-button-#{story.id}")
      expect(rendered).not_to have_css(".bookmark-button")
    end

    it "does not render the bookmark button when is_home_feed is omitted" do
      render partial: "articles/single_story", locals: { story: story, featured: false, feed_style_preference: "basic" }

      expect(rendered).not_to have_css("#article-save-button-#{story.id}")
      expect(rendered).not_to have_css(".bookmark-button")
    end

    it "does not render the bookmark button if current_user is the article author even on home feed" do
      assign(:user, author)
      render partial: "articles/single_story", locals: { story: story, is_home_feed: true, featured: false, feed_style_preference: "basic" }

      expect(rendered).not_to have_css("#article-save-button-#{story.id}")
      expect(rendered).not_to have_css(".bookmark-button")
    end
  end

  context "when user is signed out" do
    before do
      allow(view).to receive(:user_signed_in?).and_return(false)
      allow(view).to receive(:current_user).and_return(nil)
      assign(:user, nil)
    end

    it "does not render the bookmark button even if is_home_feed is true" do
      render partial: "articles/single_story", locals: { story: story, is_home_feed: true, featured: false, feed_style_preference: "basic" }

      expect(rendered).not_to have_css("#article-save-button-#{story.id}")
      expect(rendered).not_to have_css(".bookmark-button")
    end

    it "does not render the bookmark button in non-home-feed contexts" do
      render partial: "articles/single_story", locals: { story: story, featured: false, feed_style_preference: "basic" }

      expect(rendered).not_to have_css("#article-save-button-#{story.id}")
      expect(rendered).not_to have_css(".bookmark-button")
    end
  end
end
