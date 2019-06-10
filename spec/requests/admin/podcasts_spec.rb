require "rails_helper"

RSpec.describe "Admin::Podcasts", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        title: "Developer Tea",
        description: "Super Podcast",
        feed_url: "http://feeds.feedburner.com/developertea",
        slug: "devtea",
        main_color_hex: "333333"
      }
    end

    it "creates a podcast" do
      expect do
        post "/admin/podcasts", params: { podcast: valid_attributes }
      end.to change(Podcast, :count).by(1)
    end

    it "enqueues a job after creating a podcast" do
      expect do
        post "/admin/podcasts", params: { podcast: valid_attributes }
      end.to have_enqueued_job(Podcasts::GetEpisodesJob).exactly(:once)
    end
  end
end
