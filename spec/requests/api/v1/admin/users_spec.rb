require "rails_helper"

RSpec.describe "/api/admin/users" do
  let(:params) { { email: "test@example.com" } }
  let(:v1_headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  context "when unauthorized" do
    it "rejects requests without an authorization token" do
      expect do
        post api_admin_users_path, params: params, headers: v1_headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a non-admin token" do
      api_secret = create(:api_secret, user: create(:user))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_users_path, params: params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with a regular admin token" do
      api_secret = create(:api_secret, user: create(:user, :admin))
      headers = v1_headers.merge({ "api-key" => api_secret.secret })

      expect do
        post api_admin_users_path, params: params, headers: headers
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authorized" do
    let!(:super_admin) { create(:user, :super_admin) }
    let(:api_secret) { create(:api_secret, user: super_admin) }
    let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    it "accepts request with a super-admin token" do
      expect do
        post api_admin_users_path, params: params, headers: headers
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
    end

    it "enqueues an invitation email to be sent with custom options", :aggregate_failures do
      allow(DeviseMailer).to receive(:invitation_instructions).and_call_original

      assert_enqueued_with(job: Devise.mailer.delivery_job) do
        params = { email: "hey#{rand(1000)}@email.co",
                   custom_invite_subject: "Custom Subject!",
                   custom_invite_message: "**Custom message**",
                   custom_invite_footnote: "Custom footnote" }

        post api_admin_users_path, params: params, headers: headers
      end

      expect(DeviseMailer).to have_received(:invitation_instructions) do |_user, _token, args|
        expect(args).to include(
          custom_invite_subject: "Custom Subject!",
          custom_invite_message: "**Custom message**",
        )
      end
      expect(enqueued_jobs.first[:args]).to match(array_including("invitation_instructions"))
    end

    it "marks user as registered false" do
      post api_admin_users_path, params: params, headers: headers

      expect(User.last.registered).to be false
    end
  end
end
