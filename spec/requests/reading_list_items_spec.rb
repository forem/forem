require "rails_helper"

RSpec.describe "ReadingListItems" do
  let(:user) { create(:user) }
  let(:separate_user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:reaction) { create(:reaction, reactable: article, user_id: user.id) }
  let(:unauthorized_reaction) { create(:reaction, reactable: article, user_id: separate_user.id) }

  before do
    sign_in user
  end

  describe "GET reading list" do
    it "returns reading list page" do
      get "/readinglist"
      expect(response.body).to include("Reading List")
      expect(response.body).to include('id="reading-list"')
      expect(response.body).to include('data-view="valid,confirmed"')
    end

    context "when viewing archived items" do
      it "sets the correct archive view parameter" do
        get "/readinglist/archive"
        expect(response.body).to include('data-view="archived"')
      end
    end

    context "with many reading reactions" do
      before { create_list(:reading_reaction, 46, user: user) }

      it "renders successfully" do
        get "/readinglist"
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="reading-list"')
      end
    end
  end

  describe "PUT reading_list_items/:id" do
    it "returns archives item if no param" do
      expect do
        put "/reading_list_items/#{reaction.id}"
      end.to change { user.reload.last_reacted_at }
      expect(reaction.reload.status).to eq("archived")
    end

    it "unarchives an item if current_status is passed as archived" do
      expect do
        put "/reading_list_items/#{reaction.id}", params: { current_status: "archived" }
      end.to change { user.reload.last_reacted_at }
      expect(reaction.reload.status).to eq("valid")
    end

    it "raises NotAuthorizedError if current_user is not the reaction user" do
      expect { put "/reading_list_items/#{unauthorized_reaction.id}" }.to raise_error Pundit::NotAuthorizedError
    end
  end
end
