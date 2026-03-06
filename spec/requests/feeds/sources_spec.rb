require "rails_helper"

RSpec.describe "Feeds::Sources" do
  let(:user) { create(:user) }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
    sign_in user
  end

  describe "POST /feeds/sources" do
    let(:valid_params) do
      { feeds_source: { feed_url: "https://example.com/feed.xml", name: "My Blog" } }
    end

    it "creates a new feed source" do
      expect do
        post feeds_sources_path, params: valid_params
      end.to change(user.feed_sources, :count).by(1)

      source = user.feed_sources.last
      expect(source.feed_url).to eq("https://example.com/feed.xml")
      expect(source.name).to eq("My Blog")
    end

    it "redirects to feed imports dashboard" do
      post feeds_sources_path, params: valid_params
      expect(response).to redirect_to("/dashboard/feed_imports")
    end

    it "triggers a feed import" do
      allow(Feeds::ImportArticlesWorker::ForUser).to receive(:perform_async)

      post feeds_sources_path, params: valid_params

      expect(Feeds::ImportArticlesWorker::ForUser).to have_received(:perform_async).with(user.id, nil)
    end

    it "shows error for invalid feed URL" do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(false)

      post feeds_sources_path, params: { feeds_source: { feed_url: "not-a-feed" } }

      expect(response).to redirect_to("/dashboard/feed_imports")
      expect(flash[:error]).to be_present
    end

    it "rejects duplicate feed URL for same user" do
      create(:feed_source, user: user, feed_url: "https://example.com/feed.xml")

      post feeds_sources_path, params: valid_params

      expect(response).to redirect_to("/dashboard/feed_imports")
      expect(flash[:error]).to be_present
    end

    it "prevents suspended users from creating sources" do
      user.add_role(:suspended)

      expect do
        post feeds_sources_path, params: valid_params
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "PATCH /feeds/sources/:id" do
    let!(:source) { create(:feed_source, user: user, name: "Old Name") }

    it "updates the feed source" do
      patch feeds_source_path(source), params: { feeds_source: { name: "New Name" } }

      expect(source.reload.name).to eq("New Name")
      expect(response).to redirect_to("/dashboard/feed_imports")
      expect(flash[:notice]).to be_present
    end

    it "prevents updating another user's source" do
      other_source = create(:feed_source, user: create(:user))

      expect do
        patch feeds_source_path(other_source), params: { feeds_source: { name: "Hacked" } }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "DELETE /feeds/sources/:id" do
    let!(:source) { create(:feed_source, user: user) }

    it "deletes the feed source" do
      expect do
        delete feeds_source_path(source)
      end.to change(user.feed_sources, :count).by(-1)

      expect(response).to redirect_to("/dashboard/feed_imports")
      expect(flash[:notice]).to be_present
    end

    it "prevents deleting another user's source" do
      other_source = create(:feed_source, user: create(:user))

      expect do
        delete feeds_source_path(other_source)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
