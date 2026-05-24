require "rails_helper"

RSpec.describe "/api/admin/users" do
  describe "POST /api/admin/users" do
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

  describe "GET /api/admin/users" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let!(:older) { create(:user, email: "alpha@example.com", username: "alpha_user", created_at: 2.days.ago) }
    let!(:newer) { create(:user, email: "beta@example.com",  username: "beta_user",  created_at: 1.day.ago) }

    it "rejects requests without an api key" do
      get "/api/admin/users", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects non-super-admin callers" do
      get "/api/admin/users", headers: non_admin_api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns users ordered by created_at DESC" do
      get "/api/admin/users", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["users"].pluck("id")
      # `admin_api_headers` creates a super_admin caller (created_at = Time.current),
      # so the caller appears first. Newer/older follow it in DESC order.
      newer_index = ids.index(newer.id)
      older_index = ids.index(older.id)
      expect(newer_index).not_to be_nil
      expect(older_index).not_to be_nil
      expect(newer_index).to be < older_index
    end

    it "filters by exact email" do
      get "/api/admin/users", params: { email: "alpha@example.com" }, headers: admin_api_headers

      expect(response.parsed_body["users"].pluck("id")).to eq([older.id])
    end

    it "filters by exact username" do
      get "/api/admin/users", params: { username: "beta_user" }, headers: admin_api_headers

      expect(response.parsed_body["users"].pluck("id")).to eq([newer.id])
    end

    it "filters by identity_provider + identity_uid" do
      omniauth_mock_mlh_payload
      create(:identity, user: older, provider: "mlh", uid: "core-12345")

      get "/api/admin/users",
          params: { identity_provider: "mlh", identity_uid: "core-12345" },
          headers: admin_api_headers

      expect(response.parsed_body["users"].pluck("id")).to eq([older.id])
    end

    it "paginates with page and per_page" do
      get "/api/admin/users", params: { page: 1, per_page: 1 }, headers: admin_api_headers

      body = response.parsed_body
      expect(body["users"].size).to eq(1)
      expect(body["page"]).to eq(1)
      expect(body["per_page"]).to eq(1)
      expect(body["total"]).to be >= 2
    end

    it "clamps per_page above 100 to 100" do
      get "/api/admin/users", params: { per_page: 999 }, headers: admin_api_headers

      expect(response.parsed_body["per_page"]).to eq(100)
    end

    it "does not log an audit entry for reads" do
      expect do
        get "/api/admin/users", headers: admin_api_headers
      end.not_to change(AuditLog, :count)
    end
  end

  describe "GET /api/admin/users/:id" do
    let!(:user) { create(:user) }

    it "returns the user payload" do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      create(:identity, user: user, provider: "mlh", uid: "core-99")

      get "/api/admin/users/#{user.id}", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(user.id)
      expect(body["username"]).to eq(user.username)
      expect(body["identities"].pluck("uid")).to include("core-99")
    end

    it "returns 404 with error_code for missing user" do
      get "/api/admin/users/999999", headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("not_found")
    end

    it "does not log an audit entry" do
      expect do
        get "/api/admin/users/#{user.id}", headers: admin_api_headers
      end.not_to change(AuditLog, :count)
    end
  end

  describe "PATCH /api/admin/users/:id" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let!(:target) { create(:user, name: "Old Name", username: "old_username") }

    it "updates name and username" do
      patch "/api/admin/users/#{target.id}",
            params: { name: "New Name", username: "new_username" },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      target.reload
      expect(target.name).to eq("New Name")
      expect(target.username).to eq("new_username")
    end

    it "updates profile fields summary, location, website_url" do
      patch "/api/admin/users/#{target.id}",
            params: { summary: "New summary", location: "Brooklyn", website_url: "https://example.com" },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      profile = target.reload.profile
      expect(profile.summary).to eq("New summary")
      expect(profile.location).to eq("Brooklyn")
      expect(profile.website_url).to eq("https://example.com")
    end

    it "ignores unsupported fields silently" do
      patch "/api/admin/users/#{target.id}",
            params: { reputation_modifier: 99 },
            headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.reputation_modifier).not_to eq(99)
    end

    it "returns 422 with errors hash on validation failure" do
      taken_user = create(:user, username: "taken_username")
      patch "/api/admin/users/#{target.id}",
            params: { username: taken_user.username },
            headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = response.parsed_body
      expect(body["error_code"]).to eq("validation_failed")
      expect(body["errors"]).to have_key("username")
    end

    it "logs an audit entry with changed fields" do
      expect do
        patch "/api/admin/users/#{target.id}",
              params: { name: "Audit Name" },
              headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("update_user")
      expect(audit.data["target_user_id"]).to eq(target.id)
      expect(audit.data["changed"]).to include("name")
    end
  end

  describe "PUT /api/admin/users/:id/email" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let!(:target) { create(:user, email: "old@example.com") }

    it "updates email without sending a confirmation email" do
      ActionMailer::Base.deliveries.clear

      put "/api/admin/users/#{target.id}/email",
          params: { email: "new@example.com" },
          headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.email).to eq("new@example.com")
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "returns 409 email_taken on conflict" do
      create(:user, email: "taken@example.com")

      put "/api/admin/users/#{target.id}/email",
          params: { email: "taken@example.com" },
          headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("email_taken")
    end

    it "logs an audit entry" do
      expect do
        put "/api/admin/users/#{target.id}/email",
            params: { email: "audited@example.com" },
            headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("update_user_email")
      expect(audit.data).to include(
        "target_user_id" => target.id,
        "old_email" => "old@example.com",
        "new_email" => "audited@example.com",
      )
    end

    it "rejects malformed email" do
      put "/api/admin/users/#{target.id}/email",
          params: { email: "not-an-email" },
          headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("validation_failed")
    end

    it "normalizes the new email to downcased form" do
      put "/api/admin/users/#{target.id}/email",
          params: { email: "  Mixed.Case@Example.COM  " },
          headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.email).to eq("mixed.case@example.com")
    end

    it "enqueues a cache-bust for the target user" do
      sidekiq_assert_enqueued_with(job: Users::BustCacheWorker, args: [target.id]) do
        put "/api/admin/users/#{target.id}/email",
            params: { email: "bust@example.com" },
            headers: admin_api_headers
      end
    end
  end

  describe "PUT /api/admin/users/:id/status" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let!(:target) { create(:user) }

    %w[Suspended Spam Warned Trusted Limited].each do |status|
      it "applies #{status}" do
        put "/api/admin/users/#{target.id}/status",
            params: { status: status, note: "for testing" },
            headers: admin_api_headers

        expect(response).to have_http_status(:ok)
        target.reload
        case status
        when "Suspended" then expect(target.suspended?).to be true
        when "Spam"      then expect(target.spam?).to be true
        when "Warned"    then expect(target.warned?).to be true
        when "Trusted"   then expect(target.roles.exists?(name: "trusted")).to be true
        when "Limited"   then expect(target.roles.exists?(name: "limited")).to be true
        end
      end
    end

    it "applies Good standing (clears moderation roles)" do
      target.add_role(:suspended)
      put "/api/admin/users/#{target.id}/status",
          params: { status: "Good standing", note: "rehab" },
          headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.suspended?).to be false
    end

    it "rejects invalid status" do
      put "/api/admin/users/#{target.id}/status",
          params: { status: "Banishedish" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")
    end

    it "rejects role-grant statuses (Admin, Super Moderator, Tech Admin)" do
      put "/api/admin/users/#{target.id}/status",
          params: { status: "Admin" }, headers: admin_api_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")
    end

    it "audits the change" do
      expect do
        put "/api/admin/users/#{target.id}/status",
            params: { status: "Suspended", note: "auditable" }, headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)
      audit = AuditLog.last
      expect(audit.slug).to eq("update_user_status")
      expect(audit.data).to include("target_user_id" => target.id, "new_status" => "Suspended")
    end
  end

  describe "POST /api/admin/users/:id/merge" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let!(:keeper) { create(:user) }
    let!(:loser)  { create(:user) }

    it "merges loser into keeper end-to-end" do
      article = create(:article, user: loser, with_main_image: false)
      comment = create(:comment, user: loser, commentable: article)

      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: loser.id },
           headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      expect(article.reload.user_id).to eq(keeper.id)
      expect(comment.reload.user_id).to eq(keeper.id)
    end

    it "returns 409 cannot_merge_user_into_itself when ids match" do
      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: keeper.id }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("cannot_merge_user_into_itself")
    end

    it "returns 404 when merge_user_id does not exist (does not mask as conflict)" do
      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: 999_999 }, headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("not_found")
    end

    it "returns 409 merge_identity_conflict when MergeUser raises" do
      omniauth_mock_github_payload if defined?(omniauth_mock_github_payload)
      omniauth_mock_twitter_payload if defined?(omniauth_mock_twitter_payload)
      create(:identity, user: loser, provider: "github", uid: "1")
      create(:identity, user: loser, provider: "twitter", uid: "2")

      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: loser.id }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("merge_identity_conflict")
    end

    it "audits the merge" do
      expect do
        post "/api/admin/users/#{keeper.id}/merge",
             params: { merge_user_id: loser.id }, headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)
      audit = AuditLog.last
      expect(audit.slug).to eq("merge_users")
      expect(audit.data).to include("keep_user_id" => keeper.id, "deleted_user_id" => loser.id)
    end
  end
end
