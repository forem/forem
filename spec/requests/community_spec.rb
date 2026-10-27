require "rails_helper"

RSpec.describe "Community", :proper_status do
  describe "GET /community" do
    it "returns proper page" do
      get community_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Community Hub")
    end

    it "displays tags section" do
      create(:tag, name: "ruby", hotness_score: 100)
      create(:tag, name: "javascript", hotness_score: 90)

      get community_path
      expect(response.body).to include("js-tag-card")
      expect(response.body).to include("ruby")
      expect(response.body).to include("javascript")
    end

    it "displays top authors section" do
      get community_path
      expect(response.body).to include("No recent authors to display")
    end

    it "displays key pages when they exist" do
      page = create(:page, title: "About Us", slug: "about", is_top_level_path: true)

      get community_path
      expect(response.body).to include("Key Resources", "About Us")
    end

    it "displays community info sidebar" do
      get community_path
      expect(response.body).to include("About")
    end

    context "when ranking popular community members" do
      it "ranks an author with community reactions above a high-volume author with no reactions" do
        quality_author = create(:user, registered: true)
        spam_author = create(:user, registered: true)

        # Spam author has higher total_score (25 * 10 = 250) but 0 reactions.
        # On main (total_score DESC), spam_author wins; on our branch (total_reactions DESC),
        # quality_author wins.
        25.times do
          create(:article, user: spam_author, published: true,
                           score: 10, public_reactions_count: 0)
        end

        create(:article, user: quality_author, published: true,
                         score: 80, public_reactions_count: 50)
        create(:article, user: quality_author, published: true,
                         score: 60, public_reactions_count: 40)

        get community_path

        quality_pos = response.body.index(quality_author.username)
        spam_pos = response.body.index(spam_author.username)

        expect(quality_pos).to be < spam_pos
      end

      it "excludes feed-imported articles when ranking popular community members" do
        feed_bot = create(:user, registered: true)
        10.times do
          create(:article, user: feed_bot, published: true, published_from_feed: true,
                           score: 10, public_reactions_count: 5)
        end

        get community_path

        expect(response.body).not_to include(feed_bot.username)
      end

      it "excludes suspended users" do
        suspended_user = create(:user, :suspended)
        create(:article, user: suspended_user, published: true,
                         score: 50, public_reactions_count: 50)

        get community_path

        expect(response.body).not_to include(suspended_user.username)
      end

      it "excludes spam users" do
        spam_user = create(:user, :spam)
        create(:article, user: spam_user, published: true,
                         score: 50, public_reactions_count: 50)

        get community_path

        expect(response.body).not_to include(spam_user.username)
      end

      it "excludes users with negative scores" do
        negative_user = create(:user, registered: true, score: -5)
        create(:article, user: negative_user, published: true,
                         score: 50, public_reactions_count: 50)

        get community_path

        expect(response.body).not_to include(negative_user.username)
      end

      it "does not count articles with negative scores" do
        author = create(:user, registered: true)
        create(:article, user: author, published: true, score: -5)
        create(:article, user: author, published: true, score: -10)

        get community_path

        expect(response.body).not_to include(author.username)
      end

      it "excludes articles published more than 30 days ago" do
        author = create(:user, registered: true)
        create(:article, :past, past_published_at: 40.days.ago, user: author,
                                published: true, score: 50, public_reactions_count: 50)

        get community_path

        expect(response.body).not_to include(author.username)
      end

      it "excludes mascot and staff users when configured" do
        mascot = create(:user, registered: true)
        allow(Settings::General).to receive(:mascot_user_id).and_return(mascot.id)
        create(:article, user: mascot, published: true,
                         score: 100, public_reactions_count: 100)

        get community_path

        expect(response.body).not_to include(mascot.username)
      end
    end
  end
end
