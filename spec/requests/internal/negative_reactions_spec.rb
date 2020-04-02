require "rails_helper"

RSpec.describe "/internal/negative_reactions", type: :request do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get "/internal/negative_reactions"
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is an admin" do
    let(:admin)      { create(:user, :admin) }
    let(:moderator)  { create(:user, :trusted) }
    let!(:reaction)  { create(:vomit_reaction, user: moderator) }

    before do
      sign_in admin
    end

    it "does not block the request" do
      expect do
        get "/internal/negative_reactions"
      end.not_to raise_error
    end

    describe "GETS /internal/negative_reactions" do
      it "renders to appropriate page" do
        get "/internal/negative_reactions"
        expect(response.body).to include(moderator.username)
        expect(response.body).to include(reaction.category)
      end
    end
  end
end
