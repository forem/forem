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

    it "rejects requests without an api key or from non-super-admin callers", :aggregate_failures do
      get "/api/admin/users", headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)

      get "/api/admin/users", headers: non_admin_api_headers
      expect(response).to have_http_status(:unauthorized)
    end

    context "with existing users" do
      let!(:older) { create(:user, email: "alpha@example.com", username: "alpha_user", created_at: 2.days.ago) }
      let!(:newer) { create(:user, email: "beta@example.com",  username: "beta_user",  created_at: 1.day.ago) }
      let(:headers) { admin_api_headers }

      it "returns users ordered by created_at DESC without logging an audit entry", :aggregate_failures do
        expect do
          get "/api/admin/users", headers: headers
        end.not_to change(AuditLog, :count)

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

      it "paginates with page and per_page and clamps per_page above 100 to 100", :aggregate_failures do
        get "/api/admin/users", params: { page: 1, per_page: 1 }, headers: headers

        body = response.parsed_body
        expect(body["users"].size).to eq(1)
        expect(body["page"]).to eq(1)
        expect(body["per_page"]).to eq(1)
        expect(body["total"]).to be >= 2

        get "/api/admin/users", params: { per_page: 999 }, headers: headers

        expect(response.parsed_body["per_page"]).to eq(100)
      end

      it "filters by exact email, exact username, and identity_provider + identity_uid", :aggregate_failures do
        get "/api/admin/users", params: { email: "alpha@example.com" }, headers: headers
        expect(response.parsed_body["users"].pluck("id")).to eq([older.id])

        get "/api/admin/users", params: { username: "beta_user" }, headers: headers
        expect(response.parsed_body["users"].pluck("id")).to eq([newer.id])

        omniauth_mock_mlh_payload
        create(:identity, user: older, provider: "mlh", uid: "core-12345")

        get "/api/admin/users",
            params: { identity_provider: "mlh", identity_uid: "core-12345" },
            headers: headers
        expect(response.parsed_body["users"].pluck("id")).to eq([older.id])
      end
    end
  end

  describe "GET /api/admin/users/:id" do
    let(:user) { create(:user) }

    it "returns the user payload without logging an audit entry", :aggregate_failures do
      omniauth_mock_mlh_payload if defined?(omniauth_mock_mlh_payload)
      create(:identity, user: user, provider: "mlh", uid: "core-99")
      headers = admin_api_headers

      expect do
        get "/api/admin/users/#{user.id}", headers: headers
      end.not_to change(AuditLog, :count)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(user.id)
      expect(body["username"]).to eq(user.username)
      expect(body["identities"].pluck("uid")).to include("core-99")
    end

    it "returns 404 with error_code for missing user", :aggregate_failures do
      get "/api/admin/users/999999", headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("not_found")
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

    # update_columns bypasses the Trackable after_commit, so the endpoint
    # must emit explicitly or Core never learns the new address.
    it "emits user_updated to the DEV -> Core sync" do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
      Settings::General.customerio_cdp_enabled = true
      FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[target])

      with_trackable_events do
        put "/api/admin/users/#{target.id}/email",
            params: { email: "new@example.com" },
            headers: admin_api_headers
      end

      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_updated", [target.id], hash_including("email" => "new@example.com"), anything)
    ensure
      FeatureFlag.remove(:dev_core_user_sync)
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

  describe "PUT /api/admin/users/:id/notification_settings" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let(:target) { create(:user, :without_profile, profile_image: nil) }
    let(:headers) { admin_api_headers.merge("Content-Type" => "application/json") }

    it "uses the same Core-synced consent allowlist as the event emitter" do
      expect(Api::Admin::UsersController::ALLOWED_NOTIFICATION_SETTINGS)
        .to equal(Users::NotificationSetting::CORE_SYNCED_EMAIL_SETTINGS)
    end

    def put_settings(body, id: target.id)
      put "/api/admin/users/#{id}/notification_settings",
          params: body.to_json,
          headers: headers
    end

    it "updates allowlisted settings, returns every allowlisted key, and logs audit entries",
       :aggregate_failures do
      target.notification_setting.update!(email_newsletter: true)

      expect do
        put_settings({ notification_setting: { email_newsletter: false } })
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(target.notification_setting.reload.email_newsletter).to be(false)
      expect(response.parsed_body["notification_setting"]["email_newsletter"]).to be(false)
      expect(response.parsed_body["notification_setting"].keys).to match_array(
        Api::Admin::UsersController::ALLOWED_NOTIFICATION_SETTINGS.map(&:to_s),
      )

      audit = AuditLog.last
      expect(audit.slug).to eq("update_notification_settings")
      expect(audit.data["target_user_id"]).to eq(target.id)
      expect(audit.data["changes"]).to eq("email_newsletter" => [true, false])

      put_settings({ notification_setting: { email_newsletter: true, email_digest_periodic: true } })
      expect(target.notification_setting.reload.email_newsletter).to be(true)

      expect do
        put_settings({ notification_setting: { email_digest_periodic: false } })
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(target.notification_setting.reload.email_digest_periodic).to be(false)
      expect(AuditLog.last.data["changes"]).to eq("email_digest_periodic" => [true, false])

      target.notification_setting.update!(email_newsletter: true, email_digest_periodic: true)
      put_settings({ notification_setting: { email_newsletter: false,
                                             email_digest_periodic: false } })
      setting = target.notification_setting.reload
      expect(setting.email_newsletter).to be(false)
      expect(setting.email_digest_periodic).to be(false)
    end

    # Core pushes ITS OWN consent state through this endpoint; if the write
    # emitted the CDP newsletter/digest events, Core would consume its own
    # push as a user consent change (destroying the layered
    # global-unsubscribe / list-preference distinction).
    it "does not emit CDP newsletter, digest, or per-notification events for admin-API writes",
       :aggregate_failures do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
      Settings::General.customerio_cdp_enabled = true
      FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[target])
      target.notification_setting.update!(email_newsletter: true, email_digest_periodic: true)

      with_trackable_events do
        put_settings({ notification_setting: { email_newsletter: false } })
        put_settings({ notification_setting: { email_digest_periodic: false } })
        put_settings({ notification_setting: { email_comment_notifications: false,
                                               email_badge_notifications: false } })
      end

      setting = target.notification_setting.reload
      expect(setting.email_newsletter).to be(false)
      expect(setting.email_digest_periodic).to be(false)
      expect(setting.email_comment_notifications).to be(false)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    ensure
      FeatureFlag.remove(:dev_core_user_sync)
    end

    it "rejects missing wrapper or unpermitted settings with 422 and returns 404 for unknown users",
       :aggregate_failures do
      put_settings({ email_newsletter: false })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_notification_settings")

      put_settings({ notification_setting: { welcome_notifications: false } })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_notification_settings")

      put_settings({ notification_setting: { mobile_comment_notifications: false } })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(target.notification_setting.reload.mobile_comment_notifications).to be(true)

      put_settings({ notification_setting: { email_newsletter: false } }, id: 999_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT /api/admin/users/:id/status" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let(:target) { create(:user, profile_image: nil) }
    let(:headers) { admin_api_headers }

    it "applies moderation statuses, clears them with Good standing, and audits changes", :aggregate_failures do
      %w[Suspended Spam Warned Trusted Limited].each do |status|
        expect do
          put "/api/admin/users/#{target.id}/status",
              params: { status: status, note: "for testing" },
              headers: headers
        end.to change(AuditLog, :count).by(1)

        expect(response).to have_http_status(:ok)
        target.reload
        case status
        when "Suspended" then expect(target.suspended?).to be true
        when "Spam"      then expect(target.spam?).to be true
        when "Warned"    then expect(target.warned?).to be true
        when "Trusted"   then expect(target.roles.exists?(name: "trusted")).to be true
        when "Limited"   then expect(target.roles.exists?(name: "limited")).to be true
        end

        audit = AuditLog.last
        expect(audit.slug).to eq("update_user_status")
        expect(audit.data).to include("target_user_id" => target.id, "new_status" => status)
      end

      expect(target.limited?).to be true

      put "/api/admin/users/#{target.id}/status",
          params: { status: "Good standing", note: "rehab" },
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(target.reload.limited?).to be false
    end

    it "rejects invalid and role-grant statuses", :aggregate_failures do
      put "/api/admin/users/#{target.id}/status",
          params: { status: "Banishedish" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")

      put "/api/admin/users/#{target.id}/status",
          params: { status: "Admin" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error_code"]).to eq("invalid_status")
    end
  end

  describe "POST /api/admin/users/:id/merge" do
    before { Audit::Subscribe.listen :admin_api }
    after  { Audit::Subscribe.forget :admin_api }

    let(:keeper) { create(:user, :without_profile, profile_image: nil) }
    let(:loser)  { create(:user, profile_image: nil) }
    let(:headers) { admin_api_headers }

    it "merges loser into keeper, audits the merge, and deletes the merged-away user in the background",
       :aggregate_failures do
      article = create(:article, user: loser, with_main_image: false)
      comment = create(:comment, user: loser, commentable: article)

      expect do
        sidekiq_assert_enqueued_with(job: Users::DeleteWorker, args: [loser.id, true, "merge"]) do
          post "/api/admin/users/#{keeper.id}/merge",
               params: { merge_user_id: loser.id },
               headers: headers
        end
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(article.reload.user_id).to eq(keeper.id)
      expect(comment.reload.user_id).to eq(keeper.id)
      audit = AuditLog.last
      expect(audit.slug).to eq("merge_users")
      expect(audit.data).to include("keep_user_id" => keeper.id, "deleted_user_id" => loser.id)

      sidekiq_perform_enqueued_jobs(only: Users::DeleteWorker)

      expect(User.exists?(loser.id)).to be(false)
      expect(User.exists?(keeper.id)).to be(true)
    end

    it "returns 409 when ids match and 404 when merge_user_id does not exist", :aggregate_failures do
      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: keeper.id }, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("cannot_merge_user_into_itself")

      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: 999_999 }, headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error_code"]).to eq("not_found")
    end

    it "returns 409 merge_identity_conflict when MergeUser raises" do
      omniauth_mock_github_payload if defined?(omniauth_mock_github_payload)
      omniauth_mock_twitter_payload if defined?(omniauth_mock_twitter_payload)
      create(:identity, user: loser, provider: "github", uid: "1")
      create(:identity, user: loser, provider: "twitter", uid: "2")

      post "/api/admin/users/#{keeper.id}/merge",
           params: { merge_user_id: loser.id }, headers: headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error_code"]).to eq("merge_identity_conflict")
    end
  end
end
