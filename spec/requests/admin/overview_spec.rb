require "rails_helper"

RSpec.describe "/admin" do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
  end

  describe "Notices" do
    it "does not show warning if deployed at is recent" do
      allow(ForemInstance).to receive(:deployed_at).and_return(1.day.ago)
      get admin_path

      expect(response.body).not_to include("If you stay out of date for too long")
    end

    it "shows warning notice if deployed at is over two weeks ago" do
      allow(ForemInstance).to receive(:deployed_at).and_return(3.weeks.ago)
      get admin_path

      expect(response.body).to include("If you stay out of date for too long")
      expect(response.body).to include("crayons-notice--warning")
    end

    it "shows danger notice if deployed at is over four weeks ago" do
      allow(ForemInstance).to receive(:deployed_at).and_return(5.weeks.ago)
      get admin_path

      expect(response.body).to include("If you stay out of date for too long")
      expect(response.body).to include("crayons-notice--danger")
    end
  end

  describe "Last deployed and Latest Commit ID card" do
    before do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    after do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    it "shows the correct value if the Last deployed time is available" do
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => "Some date"))

      get admin_path

      expect(response.body).to include(ENV.fetch("HEROKU_RELEASE_CREATED_AT", nil))
    end
  end

  describe "analytics" do
    subject(:body) { response.body }

    before do
      get admin_path
    end

    it { is_expected.to include("Activity Statistics") }
    it { is_expected.to include("Published Posts") }
    it { is_expected.to include("Comments") }
    it { is_expected.to include("Public Reactions") }
    it { is_expected.to include("New Users") }
  end

  describe "GET /admin/stats" do
    it "returns stats for the past 7 days by default" do
      # Set super_admin registered_at outside the time period
      super_admin.update_column(:registered_at, 30.days.ago)
      
      user = create(:user, registered_at: 10.days.ago)
      
      article1 = create(:article, :past, past_published_at: 3.days.ago, user: user)
      article2 = create(:article, :past, past_published_at: 5.days.ago, user: user)
      create(:article, :past, past_published_at: 10.days.ago, user: user)
      create(:comment, commentable: article1, created_at: 2.days.ago, user: user)
      create(:reaction, reactable: article2, created_at: 4.days.ago, user: user)
      create(:user, registered_at: 1.day.ago)

      get admin_stats_path

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["published_posts"]).to eq(2)
      expect(json["comments"]).to eq(1)
      expect(json["public_reactions"]).to eq(1)
      expect(json["new_users"]).to eq(1)
      expect(json["period"]).to eq(7)
    end

    it "returns stats for the past 30 days when specified" do
      user = create(:user, registered_at: 40.days.ago)
      
      create(:article, :past, past_published_at: 15.days.ago, user: user)
      create(:article, :past, past_published_at: 5.days.ago, user: user)
      create(:article, :past, past_published_at: 35.days.ago, user: user)

      get admin_stats_path, params: { period: 30 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["published_posts"]).to eq(2)
      expect(json["period"]).to eq(30)
    end

    it "returns stats for the past 90 days when specified" do
      user = create(:user, registered_at: 110.days.ago)
      
      create(:article, :past, past_published_at: 50.days.ago, user: user)
      create(:article, :past, past_published_at: 5.days.ago, user: user)
      create(:article, :past, past_published_at: 100.days.ago, user: user)

      get admin_stats_path, params: { period: 90 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["published_posts"]).to eq(2)
      expect(json["period"]).to eq(90)
    end

    it "defaults to 7 days for invalid period values" do
      get admin_stats_path, params: { period: 999 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["period"]).to eq(7)
    end
  end
end
