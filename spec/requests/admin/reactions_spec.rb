require "rails_helper"

RSpec.describe "/admin/reactions" do
  let(:user)             { create(:user) }
  let(:article)          { create(:article, user: user) }
  let(:admin)            { create(:user, :super_admin) }

  describe "PUT /admin/reactions as admin" do
    before do
      user.add_role(:trusted)
      sign_in admin
    end

    let(:reaction) { create(:reaction, category: "vomit", user: user, reactable: article) }

    it "updates reaction to be confirmed" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmed" }
      expect(reaction.reload.status).to eq("confirmed")
    end

    it "updates reaction to be invalid" do
      initial_updated_at = reaction.reactable.updated_at

      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "invalid" }

      expect(reaction.reload.reactable.updated_at).not_to eq(initial_updated_at)
      expect(reaction.reload.status).to eq("invalid")
    end

    it "does not set a non-valid status" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmedsssss" }
      expect(reaction.reload.status).not_to eq("confirmedsssss")
    end

    it "returns HTTP Status 200 upon status update" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmed" }
      expect(response).to have_http_status(:ok)
    end

    it "returns HTTP Status 422 upon status update failure" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmedsssss" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns expected JSON upon status update" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmed" }
      expect(response.parsed_body).to eq("outcome" => "Success")
    end

    it "returns error upon status update failure" do
      put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmedsssss" }
      expect(response.parsed_body).to include("error")
    end
  end

  describe "PUT /admin/reactions as support admin" do
    let(:support_admin) { create(:user, :support_admin) }
    let(:comment)       { create(:comment, commentable: article) }

    before do
      user.add_role(:trusted)
      sign_in support_admin
    end

    context "when the reaction is on a comment" do
      let(:reaction) { create(:reaction, category: "vomit", user: user, reactable: comment) }

      it "invalidates the flag so the comment's score can recover" do
        put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "invalid" }

        expect(response).to have_http_status(:ok)
        expect(reaction.reload.status).to eq("invalid")
      end
    end

    context "when the reaction is not on a comment" do
      let(:reaction) { create(:reaction, category: "vomit", user: user, reactable: article) }

      it "does not allow the update" do
        expect do
          put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "invalid" }
        end.to raise_error(Pundit::NotAuthorizedError)

        expect(reaction.reload.status).not_to eq("invalid")
      end
    end
  end

  describe "PUT /admin/reactions as non-admin" do
    before do
      user.add_role(:trusted)
      sign_in user
    end

    let(:reaction) { create(:reaction, category: "vomit", user_id: user.id, reactable: article) }

    it "updates reaction to be confirmed" do
      invalid_request = lambda do
        put admin_reaction_path(reaction.id), params: { id: reaction.id, status: "confirmed" }
      end

      expect { invalid_request.call }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
