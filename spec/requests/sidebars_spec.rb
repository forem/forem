require "rails_helper"

RSpec.describe "Sidebars" do
  describe "GET /sidebars/home" do
    it "includes relevant parts" do
      create(:tag, name: "rubymagoo")
      allow(Settings::General).to receive(:sidebar_tags).and_return(["rubymagoo"])
      get "/sidebars/home"
      expect(response.body).to include("rubymagoo")
    end

    context "when onboarding progress is shown" do
      let(:user) { create(:user) }

      before { allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(true) }

      it "shows onboarding progress card for new signed-in user" do
        sign_in user
        get "/sidebars/home"
        expect(response.body).to include("onboarding-progress-card")
      end

      it "does not show onboarding progress card for signed-out user" do
        get "/sidebars/home"
        expect(response.body).not_to include("onboarding-progress-card")
      end

      it "does not show onboarding progress card when all items are completed" do
        checklist = user.onboarding_checklist
        OnboardingChecklist::ITEM_KEYS.each { |key| checklist.complete_item!(key) }
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include("onboarding-progress-card")
      end

      it "does not show onboarding progress card for users registered more than 28 days ago" do
        user.update_column(:registered_at, 29.days.ago)
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include("onboarding-progress-card")
      end

      it "does not show onboarding progress card when setting is disabled" do
        allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(false)
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include("onboarding-progress-card")
      end
    end

    context "when active discussions exist" do
      let(:tag) { create(:tag, name: "testmagoo") }
      let(:user) { create(:user) }
      let!(:article) do
        create(:article, tag_list: tag.name, last_comment_at: 1.day.ago, language: "en",
                         score: 10, comments_count: 5, created_at: 3.days.ago)
      end

      before do
        article.update_columns(language: "en")
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

      it "includes article without the proper tags if recently viewed and has over 1 comment" do
        second_article = create(:article, comments_count: 2)
        create(:page_view, user_id: user.id, article_id: second_article.id)
        sign_in user
        get "/sidebars/home"
        expect(response.body).to include(CGI.escapeHTML(second_article.title))
      end

      it "does not include recently-viewed page if only one comment" do
        second_article = create(:article, comments_count: 1)
        create(:page_view, user_id: user.id, article_id: second_article.id)
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include(CGI.escapeHTML(second_article.title))
      end

      it "does not include a 2 comment article if not recently viewed" do
        second_article = create(:article, comments_count: 2)
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include(CGI.escapeHTML(second_article.title))
      end

      it "does not include non-featured non-tagg-followed article" do
        second_article = create(:article, language: "en")
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include(CGI.escapeHTML(second_article.title))
      end

      it "includes article with >= 15 comments and >= 25 comment score regardless of other factors" do
        second_article = create(:article, language: "en", comments_count: 15, comment_score: 25)
        sign_in user
        get "/sidebars/home"
        expect(response.body).to include(CGI.escapeHTML(second_article.title))
      end

      it "does not include article with < 15 comments even if comment score >= 25" do
        second_article = create(:article, language: "en", comments_count: 14, comment_score: 25)
        sign_in user
        get "/sidebars/home"
        expect(response.body).not_to include(CGI.escapeHTML(second_article.title))
      end
    end

    context "when upcoming elevated events exist" do
      let!(:elevated_upcoming_event) do
        create(:event, title: "Elevated Upcoming Event", elevated: true, published: true, start_time: 1.hour.from_now, end_time: 2.hours.from_now)
      end
      let!(:non_elevated_upcoming_event) do
        create(:event, title: "Non-Elevated Upcoming Event", elevated: false, published: true, start_time: 1.hour.from_now, end_time: 2.hours.from_now)
      end
      let!(:elevated_past_event) do
        create(:event, title: "Elevated Past Event", elevated: true, published: true, start_time: 2.days.ago, end_time: 1.day.ago)
      end
      let!(:unpublished_elevated_event) do
        create(:event, title: "Unpublished Elevated Event", elevated: true, published: false, start_time: 1.hour.from_now, end_time: 2.hours.from_now)
      end

      it "includes elevated upcoming event" do
        get "/sidebars/home"
        expect(response.body).to include("Elevated Upcoming Event")
      end

      it "does not include non-elevated upcoming event" do
        get "/sidebars/home"
        expect(response.body).not_to include("Non-Elevated Upcoming Event")
      end

      it "does not include elevated past event" do
        get "/sidebars/home"
        expect(response.body).not_to include("Elevated Past Event")
      end

      it "does not include unpublished elevated event" do
        get "/sidebars/home"
        expect(response.body).not_to include("Unpublished Elevated Event")
      end
    end
  end
end