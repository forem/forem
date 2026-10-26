require "rails_helper"

RSpec.describe "users/show" do
  let!(:user) { create(:user) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:internal_navigation?).and_return(false)
      allow(view).to receive(:feed_style_preference).and_return("basic")
    end
    assign(:user, user)
    assign(:stories, [])
    assign(:comments, [])
    assign(:pinned_stories, [])
    assign(:profile, user.profile.decorate)
  end

  context "when signed-in" do
    before do
      visitor = create(:user)
      sign_in visitor
    end

    context "when there are posts" do
      let(:posts) { create_list(:article, 3) }

      before { assign :stories, posts.map(&:decorate) }

      it "renders no featured stories" do
        render
        expect(rendered).not_to have_css(".featured-story-marker")
        expect(rendered).to have_css(".crayons-story__body")
      end
    end

    context "when there are comments" do
      let(:comments) do
        article = create(:article, published: true)

        Array.new(3) do
          create(:comment, user: user, commentable: article, deleted: false)
        end
      end

      before do
        user.comments_count = 3
        assign :comments, comments.map(&:decorate)
      end

      it "renders comments as required" do
        render
        expect(rendered).not_to have_css(".crayons-story__body")
        expect(rendered).not_to have_css("#comments-locked-cta")
        expect(rendered).to have_css(".profile-comment-row")
      end
    end

    # context "when there are pinned stories" do
    #
    # end
  end

  context "when there are posts" do
    let(:posts) { create_list(:article, 3) }

    before { assign :stories, posts.map(&:decorate) }

    it "renders no featured stories" do
      render
      expect(rendered).not_to have_css(".featured-story-marker")
      expect(rendered).to have_css(".crayons-story__body")
      expect(rendered).not_to have_css("#comments-locked-cta")
    end

    it "reads the listed stories' tag colors in one cache batch" do
      allow(Rails.cache).to receive(:fetch).and_call_original
      allow(Rails.cache).to receive(:fetch_multi).and_call_original

      render

      expect(Rails.cache).to have_received(:fetch_multi).once
      expect(Rails.cache).not_to have_received(:fetch).with(a_string_ending_with("/tag_colors"), any_args)
      expect(rendered).to have_css(".crayons-story__tags a.crayons-tag", minimum: 1)
    end
  end

  context "when there are comments" do
    let(:comments) do
      article = create(:article, published: true)

      Array.new(3) do
        create(:comment, user: user, commentable: article, deleted: false)
      end
    end

    before do
      user.comments_count = 3
      assign :comments, comments.map(&:decorate)
    end

    it "does not render comments, but sign-in CTA" do
      render
      expect(rendered).not_to have_css(".profile-comment-row")
      expect(rendered).to have_css("#comments-locked-cta")
    end
  end

  it "renders without exception" do
    render
    expect(rendered).to have_css(".profile-header")
    expect(rendered).not_to have_css(".featured-story-marker")
    expect(rendered).not_to have_css(".crayons-story__body")
    expect(rendered).not_to have_css(".profile-comment-row")
    expect(rendered).not_to have_css("#comments-locked-cta")
  end

  # context "when there are pinned stories" do
  #
  # end
end
