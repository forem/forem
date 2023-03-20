require "rails_helper"

RSpec.describe "users/show" do
  let!(:user) { create(:user) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:internal_navigation?).and_return(false)
      allow(view).to receive(:feed_style_preference).and_return("basic")
    end
    assign(:user, user)
    assign(:badges_limit, 6)
    assign(:stories, [])
    assign(:comments, [])
    assign(:pinned_stories, [])
    assign(:profile, user.profile.decorate)
    assign(:is_user_flagged, false)
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
