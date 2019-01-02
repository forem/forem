require "rails_helper"

RSpec.describe "/internal/reactions", type: :request do
  let(:user)             { create(:user) }
  let(:article)          { create(:article, user_id: user.id) }
  let(:admin)            { create(:user, :super_admin) }

  describe "PUT /internal/reactions as admin" do
    before do
      user.add_role(:trusted)
      login_as admin
    end

    let(:reaction) { create(:reaction, category: "vomit", user_id: user.id, reactable_id: article.id) }

    it "updates reaction to be confirmed" do
      put "/internal/reactions/#{reaction.id}", params: {
        reaction: { status: "confirmed" }
      }
      expect(reaction.reload.status).to eq("confirmed")
    end

    it "does not set invalid status" do
      put "/internal/reactions/#{reaction.id}", params: {
        reaction: { status: "confirmedsssss" }
      }
      expect(reaction.reload.status).not_to eq("confirmedsssss")
    end
  end

  describe "PUT /internal/reactions as non-admin" do
    before do
      user.add_role(:trusted)
      login_as user
    end

    let(:reaction) { create(:reaction, category: "vomit", user_id: user.id, reactable_id: article.id) }

    it "updates reaction to be confirmed" do
      expect {
        put "/internal/reactions/#{reaction.id}", params: {
          reaction: { status: "confirmed" }
        } }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
