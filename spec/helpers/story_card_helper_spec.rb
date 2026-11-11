require "rails_helper"

RSpec.describe StoryCardHelper do
  let(:author) { create(:user, name: "Ada & <Lovelace>") }
  let(:organization) { create(:organization, name: "Analytical & Engine") }
  let(:article) do
    create(
      :article,
      user: author,
      organization: organization,
      title: "Computing <Numbers> & 'Notes'",
      tags: "ruby, rust",
    )
  end

  before do
    allow(InlineSvg::IdGenerator::Randomness).to receive(:call).and_return("fixed")
    allow(helper).to receive(:user_signed_in?).and_return(false)
    helper.define_singleton_method(:feed_style_preference) { "basic" }
  end

  describe "#render_story_card" do
    it "returns an empty html_safe string when story is nil" do
      result = helper.render_story_card(nil)
      expect(result).to eq("")
      expect(result).to be_html_safe
    end

    it "renders a story card matching the legacy ERB partial byte-for-byte" do
      story = article.decorate
      native_html = helper.render_story_card(story, featured: true, pinned: true)
      legacy_html = helper.__send__(:legacy_render_story_card, story, featured: true, pinned: true)

      expect(native_html).to eq(legacy_html)
      expect(native_html).to be_html_safe
    end

    it "never calls current_user on non-curation feed renders (edge-cache safety)" do
      allow(FeatureFlag).to receive(:enabled?).and_call_original
      allow(FeatureFlag).to receive(:enabled?).with(:community_favorites).and_return(true)
      article.update_column(:favorited_by_user_id, author.id)
      allow(helper).to receive(:user_signed_in?).and_return(true)

      current_user_called = false
      helper.define_singleton_method(:current_user) do
        current_user_called = true
        nil
      end

      html = helper.render_story_card(article.decorate, featured: false, is_home_feed: true)
      expect(current_user_called).to be(false)
      expect(html).to include("data-favorited-marker")
      expect(html).to include("article-save-button-#{article.id}")
    end
  end

  describe "#render_story_cards" do
    let(:second_article) { create(:article, user: author, title: "Second Story", main_image: nil) }

    it "renders a multi-story collection in a single batch matching legacy ERB byte-for-byte" do
      article.update_column(:main_image, "https://s3.amazonaws.com/bucket/first.png")
      stories = [article.decorate, second_article.decorate]
      featured_fn = ->(s) { s.main_image.present? }

      native_html = helper.render_story_cards(stories, featured_for: featured_fn)
      legacy_html = helper.__send__(:legacy_render_story_cards, stories, featured_for: featured_fn)

      expect(native_html).to eq(legacy_html)
      expect(native_html).to include("crayons-story--featured")
    end

    it "falls back cleanly to legacy_render_story_cards when ForemNative returns nil" do
      allow(ForemNative).to receive(:render_story_cards).and_return(nil)

      stories = [article.decorate]
      expect(helper.render_story_cards(stories, featured: false)).to include(CGI.escapeHTML(article.title))
    end
  end
end
