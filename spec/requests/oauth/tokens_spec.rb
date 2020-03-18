require "rails_helper"

RSpec.describe "Oauth::Tokens", type: :request do
  let(:oauth_app) { create(:application) }
  let(:user) { create(:user) }
  let(:oauth_client) { Doorkeeper::OAuth::Client.new(oauth_app) }
  let(:access_token) { create(:doorkeeper_access_token, application: oauth_app, resource_owner: user) }
  let!(:user_webhook) { create(:webhook_endpoint, user: user, oauth_application: oauth_app) }
  let!(:user_webhook2) { create(:webhook_endpoint, user: user, oauth_application: oauth_app) }

  context "when authorization succeeds" do
    # rubocop:disable RSpec/AnyInstance
    before do
      allow_any_instance_of(Doorkeeper::Server).to receive(:client) { oauth_client }
    end
    # rubocop:enable RSpec/AnyInstance

    it "destroys webhooks" do
      user2_webhook = create(:webhook_endpoint, oauth_application: oauth_app)
      another_app_webhook = create(:webhook_endpoint)

      sidekiq_perform_enqueued_jobs do
        post oauth_revoke_path, params: { token: access_token.token }
      end
      expect(Webhook::Endpoint.find_by(id: user_webhook.id)).to be_nil
      expect(Webhook::Endpoint.find_by(id: user_webhook2.id)).to be_nil
      expect(user2_webhook.reload).to be_persisted
      expect(another_app_webhook.reload).to be_persisted
    end

    it "returns 200" do
      post oauth_revoke_path, params: { token: access_token.token }

      expect(response.status).to eq 200
    end

    it "revokes the access token" do
      post oauth_revoke_path, params: { token: access_token.token }

      expect(access_token.reload).to have_attributes(revoked?: true)
    end
  end

  context "when authorization fails" do
    let(:some_other_client) { create(:application, confidential: true) }
    let(:oauth_client) { Doorkeeper::OAuth::Client.new(some_other_client) }

    it "returns 403" do
      post oauth_revoke_path, params: { token: access_token.token }

      expect(response.status).to eq 403
    end

    it "does not revoke the access token" do
      post oauth_revoke_path, params: { token: access_token.token }

      expect(access_token.reload).to have_attributes(revoked?: false)
    end

    it "doesn't destroy webhooks" do
      sidekiq_perform_enqueued_jobs do
        post oauth_revoke_path, params: { token: access_token.token }
      end
      expect(user_webhook.reload).to be_persisted
      expect(user_webhook2.reload).to be_persisted
    end
  end
end
