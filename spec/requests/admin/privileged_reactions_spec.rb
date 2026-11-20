require "rails_helper"

RSpec.describe "/admin/moderations/privileged_reactions" do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_privileged_reactions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: ModeratorAction) }

    it "renders with status 200" do
      sign_in single_resource_admin
      get admin_moderator_actions_path
      expect(response).to have_http_status :ok
    end
  end

  context "when the user is an admin" do
    let(:admin)              { create(:user, :admin) }
    let(:moderator)          { create(:user, :trusted) }
    let!(:user_reaction)     { create(:vomit_reaction, :user, user: moderator) }
    let!(:comment_reaction)  { create(:vomit_reaction, :comment, user: moderator) }
    let!(:article_reaction)  { create(:vomit_reaction, user: moderator) }

    before do
      sign_in admin
    end

    it "does not block the request" do
      expect do
        get admin_privileged_reactions_path
      end.not_to raise_error
    end

    describe "GETS /admin/moderations/privileged_reactions" do
      it "renders to appropriate page" do
        get admin_privileged_reactions_path
        expect(response.body).to include(CGI.escapeHTML(moderator.username))
          .and include(CGI.escapeHTML(user_reaction.reactable.username))
          .and include(CGI.escapeHTML(comment_reaction.reactable.user.username))
          .and include(CGI.escapeHTML(article_reaction.reactable.title))
      end

      it "uses countless pagination and avoids N+1 queries or heavy body column hydration" do
        second_comment = create(:comment)
        create(:vomit_reaction, reactable: second_comment, user: moderator)

        queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get admin_privileged_reactions_path
        end

        reaction_count_queries = queries.grep(/SELECT COUNT.*FROM "reactions"/i)
        expect(reaction_count_queries).to be_empty

        user_queries = queries.grep(/SELECT .* FROM "users" WHERE "users"\."id"/i)
        expect(user_queries.size).to be <= 3

        article_queries = queries.grep(/SELECT .* FROM "articles"/i)
        expect(article_queries).not_to be_empty
        expect(article_queries.join(" ")).not_to include("body_markdown", "processed_html")

        comment_queries = queries.grep(/SELECT .* FROM "comments"/i)
        expect(comment_queries).not_to be_empty
        expect(comment_queries.join(" ")).not_to include("body_markdown", "processed_html")
      end

      it "filters by username and category using an indexed user subquery instead of a table join" do
        other_mod = create(:user, :trusted, username: "distinct_mod_filter_target")
        thumbsup_article = create(:article)
        create(:reaction, category: "thumbsup", reactable: thumbsup_article, user: other_mod)

        queries = []
        callback = lambda do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get admin_privileged_reactions_path, params: {
            q: { user_username_cont: "distinct_mod_filter", category_eq: "thumbsup" }
          }
        end

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(thumbsup_article.title))
        expect(response.body).not_to include(CGI.escapeHTML(article_reaction.reactable.title))

        reaction_queries = queries.grep(/FROM "reactions"/i)
        expect(reaction_queries.join(" ")).to include("ANY(ARRAY(SELECT users.id FROM users WHERE users.username ILIKE")
        expect(reaction_queries.join(" ")).not_to include('LEFT OUTER JOIN "users"')
      end
    end
  end
end
