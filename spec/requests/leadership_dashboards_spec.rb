require "rails_helper"

RSpec.describe "Leadership dashboard" do
  let(:leader) { create(:user, :community_leader_level_1) }

  describe "GET /leadership" do
    context "when signed in as a community leader" do
      before { sign_in leader }

      it "defaults to the curation section and shows both section links" do
        get leadership_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("views.leadership.curation.heading"))
        expect(response.body).to include(I18n.t("views.leadership.discussion.heading"))
      end

      it "renders the section nav for both viewports and marks the current section" do
        get leadership_section_path("discussion")

        page = Capybara.string(response.body)

        # Stacked links on wide viewports, tabs on narrow ones.
        expect(page).to have_css("nav.m\\:block a.crayons-link--block", count: 2)
        expect(page).to have_css("nav.m\\:hidden a.crayons-tabs__item", count: 2)

        current = page.all("[aria-current='page']").map { |link| link.text.strip }.uniq
        expect(current).to eq([I18n.t("views.leadership.discussion.heading")])
      end

      it "shows the leader's favorited content in the curation section" do
        favorited = create(:article)
        favorited.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)

        get leadership_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(favorited.title)
        expect(response.body).to include(CGI.escapeHTML(favorited.user.name))
      end

      it "shows favorited comments alongside favorited posts" do
        commented_on = create(:article)
        comment = create(:comment, commentable: commented_on)
        comment.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)

        get leadership_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(comment.user.name))
      end

      it "renders the suggested discussion feed" do
        surfaced = create(:article, user: create(:user))
        surfaced.update_columns(score: 100, comments_count: 0)

        get leadership_section_path("discussion")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(surfaced.title)
        expect(response.body).to include(CGI.escapeHTML(surfaced.cached_user.name))
        expect(response.body).to include(I18n.t("views.leadership.discussion.cta"))
      end

      it "excludes the leader's own posts from the discussion feed" do
        own = create(:article, user: leader)
        own.update_columns(score: 100, comments_count: 0)

        get leadership_section_path("discussion")

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(own.title)
      end

      it "accepts pagination params on each section" do
        get leadership_path(page: 2)
        expect(response).to have_http_status(:ok)

        get leadership_section_path("discussion", page: 2)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when signed in as a non-leader" do
      it "returns 404" do
        sign_in create(:user)

        get leadership_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when signed out" do
      it "does not render the dashboard" do
        get leadership_path

        expect(response).not_to have_http_status(:ok)
      end
    end
  end
end
