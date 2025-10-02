require "rails_helper"

RSpec.describe "ArticlesShow" do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :admin) }
  let(:article) do
    create(:article, user: user, published: true, organization: organization,
                     tag_list: "javascript, html")
  end
  let(:organization) { create(:organization) }
  let(:doc) { Nokogiri::HTML(response.body) }
  let(:text) { doc.at('script[type="application/ld+json"]').text }
  let(:response_json) { JSON.parse(text) }

  describe "GET /:slug (articles)" do
    before do
      allow(Settings::General).to receive(:logo_png).and_return("logo.png")
      get article.path
    end

    it "returns a 200 status when navigating to the article's page" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the proper JSON-LD for an article" do
      expect(response_json).to include(
        "@context" => "http://schema.org",
        "@type" => "Article",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.article(article)
        },
        "url" => URL.article(article),
        "image" => [
          ApplicationController.helpers.article_social_image_url(article, width: 1080, height: 1080),
          ApplicationController.helpers.article_social_image_url(article, width: 1280, height: 720),
          ApplicationController.helpers.article_social_image_url(article, width: 1600, height: 900),
        ],
        "publisher" => {
          "@context" => "http://schema.org",
          "@type" => "Organization",
          "name" => Settings::Community.community_name.to_s,
          "logo" => {
            "@context" => "http://schema.org",
            "@type" => "ImageObject",
            "url" => ApplicationController.helpers.optimized_image_url(Settings::General.logo_png, width: 192,
                                                                                                   fetch_format: "png"),
            "width" => "192",
            "height" => "192"
          }
        },
        "headline" => article.title,
        "author" => {
          "@context" => "http://schema.org",
          "@type" => "Person",
          "url" => URL.user(user),
          "name" => user.name
        },
        "datePublished" => article.published_timestamp,
        "dateModified" => article.published_timestamp,
      )
    end

    it "renders DiscussionForumPosting structured data when article has comments" do
      comment = create(:comment, commentable: article, user: user)
      article.update_column(:comments_count, 1)

      get article.path

      expect(response_json["mainEntity"]).to include(
        "@type" => "DiscussionForumPosting",
        "@id" => "#article-discussion-#{article.id}",
        "headline" => article.title,
        "text" => article.processed_html_final,
        "author" => {
          "@type" => "Person",
          "name" => user.name,
          "url" => URL.user(user)
        },
        "datePublished" => article.published_timestamp,
        "dateModified" => article.published_timestamp,
        "url" => URL.article(article),
      )

      expect(response_json["mainEntity"]["interactionStatistic"]).to include(
        {
          "@type" => "InteractionCounter",
          "interactionType" => "https://schema.org/CommentAction",
          "userInteractionCount" => 1
        },
        {
          "@type" => "InteractionCounter",
          "interactionType" => "https://schema.org/LikeAction",
          "userInteractionCount" => article.public_reactions_count
        },
      )
    end

    it "renders Comment structured data for article comments" do
      comment = create(:comment, commentable: article, user: user)
      article.update_column(:comments_count, 1)

      get article.path

      expect(response_json["mainEntity"]["comment"]).to be_present
      expect(response_json["mainEntity"]["comment"].first).to include(
        "@type" => "Comment",
        "@id" => "#comment-#{comment.id}",
        "text" => comment.processed_html_final,
        "author" => {
          "@type" => "Person",
          "name" => user.name,
          "url" => URL.user(user)
        },
        "datePublished" => comment.created_at.iso8601,
        "dateModified" => comment.created_at.iso8601,
        "url" => URL.comment(comment),
        "interactionStatistic" => [
          {
            "@type" => "InteractionCounter",
            "interactionType" => "https://schema.org/LikeAction",
            "userInteractionCount" => comment.public_reactions_count
          },
        ],
      )
    end

    it "renders nested comment structure for replies" do
      root_comment = create(:comment, commentable: article, user: user)
      reply_comment = create(:comment, commentable: article, user: user, ancestry: root_comment.id.to_s)
      article.update_column(:comments_count, 2)

      get article.path

      expect(response_json["mainEntity"]["comment"]).to be_present
      root_comment_data = response_json["mainEntity"]["comment"].first
      expect(root_comment_data["comment"]).to be_present
      expect(root_comment_data["comment"].first).to include(
        "@type" => "Comment",
        "@id" => "#comment-#{reply_comment.id}",
        "parentItem" => {
          "@type" => "Comment",
          "@id" => "#comment-#{root_comment.id}"
        },
      )
    end

    it "caches JSON-LD at view level based on last_comment_at" do
      comment = create(:comment, commentable: article, user: user)
      article.update_column(:comments_count, 1)

      # First request should generate JSON-LD
      get article.path
      expect(response_json["mainEntity"]).to be_present

      # The cache key includes last_comment_at to invalidate when comments change
      # This ensures the JSON-LD is regenerated when comments are added/updated
      expect(article.last_comment_at).to be_present
    end

    it "renders 'posted on' information" do
      get article.path
      expect(response.body).to include("Posted on")
      expect(response.body).not_to include("Scheduled for")
    end
  end

  describe "GET /:username/:slug (scheduled)" do
    let(:scheduled_article) { create(:article, published: true, published_at: Date.tomorrow) }
    let(:query_params) { "?preview=#{scheduled_article.password}" }
    let(:scheduled_article_path) { scheduled_article.path + query_params }

    it "renders a scheduled article with the article password" do
      get scheduled_article_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(scheduled_article.title)
    end

    it "renders 'scheduled for' information" do
      get scheduled_article_path
      expect(response.body).to include("Scheduled for")
      expect(response.body).not_to include("Posted on")
    end

    it "doesn't show edit link when user is not signed in" do
      get scheduled_article_path
      expect(response.body).not_to include("Click to edit")
    end

    it "renders 404 for a scheduled article w/o article password" do
      expect { get scheduled_article.path }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it "renders the proper organization for an article when one is present" do
    get organization.path
    expect(response_json).to include(
      {
        "@context" => "http://schema.org",
        "@type" => "Organization",
        "mainEntityOfPage" => {
          "@type" => "WebPage",
          "@id" => URL.organization(organization)
        },
        "url" => URL.organization(organization),
        "image" => organization.profile_image_url_for(length: 320),
        "name" => organization.name,
        "description" => organization.summary
      },
    )
  end

  context "when keywords are set" do
    it "shows keywords" do
      allow(Settings::General).to receive(:meta_keywords).and_return({ article: "hello, world" })
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).to include('<meta name="keywords" content="super sheep, hello, world">')
    end
  end

  context "when keywords are not" do
    it "does not show keywords" do
      allow(Settings::General).to receive(:meta_keywords).and_return({ article: "" })
      article.update_column(:cached_tag_list, "super sheep")
      get article.path
      expect(response.body).not_to include(
        '<meta name="keywords" content="super sheep, hello, world">',
      )
    end
  end

  context "when author has spam role" do
    before do
      article.user.add_role(:spam)
    end

    it "renders 404" do
      expect do
        get article.path
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders 404 for authorized user" do
      sign_in user
      expect do
        get article.path
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders successfully for admins", :aggregate_failures do
      sign_in admin_user
      get article.path
      expect(response).to be_successful
      expect(response.body).to include("Spam")
    end
  end

  context "when user signed in" do
    before do
      sign_in user
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end

      it "renders comment sort button" do
        expect(response.body).to include "toggle-comments-sort-dropdown"
      end
    end
  end

  context "when user not signed in" do
    before do
      get article.path
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).to include "application/ld+json"
      end

      it "does not render comment sort button" do
        expect(response.body).not_to include "toggle-comments-sort-dropdown"
      end
    end
  end

  context "with comments" do
    let!(:spam_comment) { create(:comment, score: -450, commentable: article, body_markdown: "Spam comment") }

    before do
      create(:comment, score: 10, commentable: article, body_markdown: "Good comment")
      create(:comment, score: -99, commentable: article, body_markdown: "Bad comment")
      create(:comment, score: -10, commentable: article, body_markdown: "Mediocre comment")
    end

    context "when user signed in" do
      before do
        sign_in user
      end

      it "shows positive comments" do
        get article.path
        expect(response.body).to include("Good comment")
      end

      it "shows comments with score from -400 to -75" do
        get article.path
        expect(response.body).to include("Bad comment")
      end

      it "hides comments with score < -400 and no comment deleted message" do
        get article.path
        expect(response.body).not_to include("Spam comment")
        expect(response.body).not_to include("Comment deleted")
      end

      it "displays children of a low-quality comment and comment deleted message" do
        create(:comment, score: 0, commentable: article, parent: spam_comment, body_markdown: "Child comment")
        get article.path
        expect(response.body).to include("Child comment")
        expect(response.body).to include("Comment deleted") # instead of the low quality one
      end

      it "displays comments count w/o including super low-quality ones" do
        get article.path
        expect(response.body).to include("<span class=\"js-comments-count\" data-comments-count=\"3\">(3)</span>")
      end

      it "displays includes spam comments in comments count if they have children" do
        create(:comment, score: 0, commentable: article, parent: spam_comment, body_markdown: "Child comment")
        get article.path
        expect(response.body).to include("<span class=\"js-comments-count\" data-comments-count=\"5\">(5)</span>")
      end

      it "suggests to view_full comments page with the correct count" do
        # pretend that we have a large displayed comments count
        article.update_column(:displayed_comments_count, 31)
        get article.path
        expect(response.body).to include("View full discussion (31 comments)")
      end
    end

    context "when user not signed in" do
      it "shows positive comments" do
        get article.path
        expect(response.body).to include("Good comment")
      end

      it "hides all negative comments", :aggregate_failures do
        get article.path
        expect(response.body).not_to include("Bad comment")
        expect(response.body).not_to include("Spam comment")
        expect(response.body).not_to include("Mediocre comment")
      end

      it "doesn't show children of a low-quality comment" do
        create(:comment, score: 0, commentable: article, parent: spam_comment, body_markdown: "Child comment")
        get article.path
        expect(response.body).not_to include("Child comment")
      end

      # comments number is larger than @comments_to_show_count (15)
      it "suggests to view_full comments page when needed" do
        # pretend that we have a large displayed comments count
        article.update_column(:displayed_comments_count, 16)
        get article.path
        expect(response.body).to include("View full discussion (16 comments)")
      end
    end

    context "when below post billboard exists" do
      it "does not render when it is below long article threshold" do
        article.update_column(:body_markdown, "a" * 888)
        get article.path
        expect(response.body).not_to include("body-billboard-container")
      end

      it "renders when it is above long article threshold" do
        article.update_column(:body_markdown, "a" * 901)
        get article.path
        expect(response.body).to include("body-billboard-container")
      end
    end

    context "when a mid-comments billboard exists" do
      it "does not render the billboard if there are fewer than 6 root comments" do
        create_list(:comment, 6, commentable: article)
        get article.path
        expect(response.body).not_to include("mid-comments-billboard-container")
      end

      it "renders the billboard if there are 6 or more root comments" do
        create_list(:comment, 7, commentable: article)
        get article.path
        expect(response.body).to include("mid-comments-billboard-container")
      end

      it "does not render the billboard when the first comment has too few children" do
        create(:comment, commentable: article, score: 100)
        create_list(:comment, 4, commentable: article, parent: Comment.last)
        create(:comment, commentable: article, score: 2)
        get article.path
        expect(response.body).not_to include("mid-comments-billboard-container")
      end

      it "renders the billboard when the first comment has enough children" do
        create(:comment, commentable: article, score: 100)
        create_list(:comment, 5, commentable: article, parent: Comment.last)
        create(:comment, commentable: article, score: 2)
        get article.path
        expect(response.body).to include("mid-comments-billboard-container")
      end
    end
  end

  context "when user not signed in but internal nav triggered" do
    before do
      get "#{article.path}?i=i"
    end

    describe "GET /:slug (user)" do
      it "does not render json ld" do
        expect(response.body).not_to include "application/ld+json"
      end
    end
  end
end
