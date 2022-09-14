require "rails_helper"

RSpec.describe "/admin/moderations/privileged_reactions", type: :request do
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
    end
  end
end
