require "rails_helper"

RSpec.describe "/admin/advanced/feed_configs" do
  let(:get_resource) { get admin_feed_configs_path }
  let(:params) do
    {
      feed_config: {
        ai_disclosure_matching_weight: 15.0,
        autonomous_ai_penalty_weight: 25.0,
        favorited_weight: 8.5,
        user_follow_weight: 2.0,
        tag_follow_weight: 3.0,
        score_weight: 1.5
      }
    }
  end
  let(:post_resource) { post admin_feed_configs_path, params: params }

  context "when the user is not signed in" do
    it "redirects to sign in or blocks access" do
      expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before { sign_in user }

    describe "GET /admin/advanced/feed_configs" do
      it "blocks the request" do
        expect { get_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    describe "POST /admin/advanced/feed_configs" do
      it "blocks the request" do
        expect { post_resource }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }
    let!(:top_config) { create(:feed_config, feed_success_score: 95.5, feed_impressions_count: 5000, ai_disclosure_matching_weight: 10.0) }
    let!(:other_config) { create(:feed_config, feed_success_score: 50.0, feed_impressions_count: 1000, ai_disclosure_matching_weight: 5.0) }

    before { sign_in super_admin }

    describe "GET /admin/advanced/feed_configs" do
      it "allows the request and renders the index page" do
        get_resource
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Feed Configurations")
        expect(response.body).to include("Feed Config ##{top_config.id}")
      end
    end

    describe "GET /admin/advanced/feed_configs/:id" do
      it "renders the show view for the feed config" do
        get admin_feed_config_path(top_config)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Feed Config ##{top_config.id}")
        expect(response.body).to include("ai_disclosure_matching_weight")
      end
    end

    describe "GET /admin/advanced/feed_configs/new" do
      it "pre-populates the new form with attributes from the best performing config" do
        get new_admin_feed_config_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('value="10.0"')
      end

      it "pre-populates with specified clone_from_id config when passed" do
        get new_admin_feed_config_path(clone_from_id: other_config.id)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('value="5.0"')
      end
    end

    describe "POST /admin/advanced/feed_configs" do
      it "creates a new feed config" do
        expect { post_resource }.to change(FeedConfig, :count).by(1)
        new_config = FeedConfig.last
        expect(new_config.ai_disclosure_matching_weight).to eq(15.0)
        expect(new_config.autonomous_ai_penalty_weight).to eq(25.0)
        expect(new_config.favorited_weight).to eq(8.5)
        expect(new_config.user_follow_weight).to eq(2.0)
        expect(response).to redirect_to(admin_feed_config_path(new_config))
      end
    end

    describe "DELETE /admin/advanced/feed_configs/:id" do
      it "destroys the feed config and redirects to index" do
        expect do
          delete admin_feed_config_path(other_config)
        end.to change(FeedConfig, :count).by(-1)
        expect(response).to redirect_to(admin_feed_configs_path)
      end
    end
  end
end
