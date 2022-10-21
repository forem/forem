require "rails_helper"

RSpec.describe "/admin/member_manager/users", type: :request do
  let!(:user) do
    omniauth_mock_github_payload
    create(:user, :with_identity, identities: ["github"])
  end
  let(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "GET /admin/member_manager/users" do
    it "renders to appropriate page" do
      get admin_users_path
      expect(response.body).to include(user.username)
    end

    context "when searching" do
      it "finds the proper user by GitHub username" do
        get "#{admin_users_path}?search=#{user.github_username}"
        expect(response.body).to include(CGI.escapeHTML(user.github_username))
      end
    end

    context "when filtering by role" do
      it "filters and shows the proper user(s)" do
        get "#{admin_users_path}?search&role=super_admin"
        expect(response.body).to include(CGI.escapeHTML(admin.name))
      end
    end
  end

  describe "GET /admin/member_manager/users/:id" do
    it "renders to appropriate page" do
      get admin_user_path(user)

      expect(response.body).to include(user.username)
    end

    it "redirects from /username/moderate" do
      get "/#{user.username}/moderate"
      expect(response).to redirect_to(admin_user_path(user.id))
    end

    it "shows banish button for new users" do
      get admin_user_path(user.id)
      expect(response.body).to include("Banish user")
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get admin_user_path(user.id) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "displays a user's current roles in the 'Overview' tab" do
      get admin_user_path(user.id)
      expect(response.body).to include("Roles")
    end

    it "displays a user's current roles in the 'Emails' tab" do
      get "#{admin_user_path(user.id)}?tab=emails"
      expect(response.body).to include("Previous emails")
    end

    it "displays a user's current flags in the 'Flags' tab" do
      get "#{admin_user_path(user.id)}?tab=flags"
      expect(response.body).to include("Flags received")
    end

    it "displays a message when there are no related vomit reactions for a user" do
      get "#{admin_user_path(user.id)}?tab=flags"
      expect(response.body).to include("No flags received against")
    end

    it "displays a list of recent related vomit reactions for a user if any exist" do
      vomit = build(:reaction, category: "vomit", user_id: user.id, reactable_type: "Article", status: "valid")
      get admin_user_path(user.id)
      expect(response.body).to include(vomit.reactable_type)
    end

    it "displays a user's current reports in the 'Reports' tab" do
      get "#{admin_user_path(user.id)}?tab=reports"
      expect(response.body).to include("Reports submitted by")
    end

    it "displays a message when there are no current reports for a user" do
      get "#{admin_user_path(user.id)}?tab=reports"
      expect(response.body).to include("No comment or post has been reported yet.")
    end

    it "displays a list of current reports for a user if any exist" do
      report = build(:feedback_message, category: "spam", affected_id: user.id, feedback_type: "spam", status: "Open")
      get admin_user_path(user.id)
      expect(response.body).to include(report.feedback_type)
    end

    it "displays unpublish all data from logs when it exists on unpublish_alls tab" do
      article = create(:article, user: user, published: false)
      create(:audit_log, user: admin, slug: "unpublish_all_articles",
                         data: { target_article_ids: [article.id], target_user_id: user.id })
      get "#{admin_user_path(user.id)}?tab=unpublish_logs"
      expect(response.body).to include("Unpublished by")
      expect(response.body).to include(CGI.escapeHTML(article.title))
    end

    it "displays a label if an unpublished post was republished" do
      article = create(:article, user: user, published: true)
      create(:audit_log, user: admin, slug: "unpublish_all_articles",
                         data: { target_article_ids: [article.id], target_user_id: user.id })
      get "#{admin_user_path(user.id)}?tab=unpublish_logs"
      expect(response.body).to include(CGI.escapeHTML(article.title))
      expect(response.body).to include("(was republished)")
    end

    it "displays nothing on unpublish_alls tab if it the log doesn't exist" do
      get "#{admin_user_path(user.id)}?tab=unpublish_logs"
      expect(response).to be_successful
      expect(response.body).not_to include("Unpublished by")
    end
  end

  describe "POST /admin/member_manager/users/:id/banish" do
    it "bans user for spam" do
      allow(Moderator::BanishUserWorker).to receive(:perform_async)
      post banish_admin_user_path(user.id)
      expect(Moderator::BanishUserWorker).to have_received(:perform_async).with(admin.id, user.id)
      expect(request.flash[:success]).to include("This user is being banished in the background")
    end
  end

  describe "POST /admin/member_manager/users/:id/send_email" do
    let(:params) do
      {
        email_body: "Body",
        email_subject: "subject",
        user_id: user.id.to_s
      }
    end
    let(:mailer) { double }
    let(:message_delivery) { double }

    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    end

    context "when interacting via a browser" do
      it "returns not found for non existing users" do
        expect { post send_email_admin_user_path(9999), params: params }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(NotifyMailer).to receive(:with).with(params).and_return(mailer)
        allow(mailer).to receive(:user_contact_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post send_email_admin_user_path(user.id), params: params
        end

        expect(response).to redirect_to(admin_user_path)
        expect(flash[:danger]).to include("failed")
      end

      it "sends an email to the user", :aggregate_failures do
        assert_emails(1) do
          post send_email_admin_user_path(user.id), params: params
        end

        expect(response).to redirect_to(admin_user_path)
        expect(flash[:success]).to include("sent")

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(params[:email_subject])
        expect(email.text_part.body).to include(params[:email_body])
      end
    end

    context "when interacting via ajax" do
      it "returns not found for non existing users" do
        expect do
          post send_email_admin_user_path(9999), params: params, xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(NotifyMailer).to receive(:with).with(params).and_return(mailer)
        allow(mailer).to receive(:user_contact_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post send_email_admin_user_path(user.id), params: params, xhr: true
        end

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("failed")
      end

      it "sends an email to the user", :aggregate_failures do
        assert_emails(1) do
          post send_email_admin_user_path(user.id), params: params, xhr: true
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq(params[:email_subject])
        expect(email.text_part.body).to include(params[:email_body])
      end
    end
  end

  describe "POST /admin/member_manager/users/:id/verify_email_ownership" do
    let(:mailer) { double }
    let(:message_delivery) { double }

    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    end

    context "when interacting via a browser" do
      it "returns not found for non existing users" do
        expect do
          post verify_email_ownership_admin_user_path(9999), params: { user_id: user.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(VerificationMailer).to receive(:with).with(user_id: user.id.to_s).and_return(mailer)
        allow(mailer).to receive(:account_ownership_verification_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }
        end

        expect(response).to redirect_to(admin_user_path)
        expect(flash[:danger]).to include("failed")
      end

      it "sends an email", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }
        end

        expect(response).to redirect_to(admin_user_path)
        expect(flash[:success]).to include("sent")
      end

      it "allows a user to verify email ownership", :aggregate_failures do
        post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }

        path = verify_email_authorizations_path(
          confirmation_token: user.email_authorizations.first.confirmation_token,
          username: user.username,
        )
        verification_link = app_url(path)

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq("Verify Your #{Settings::Community.community_name} Account Ownership")
        expect(email.text_part.body).to include(verification_link)

        sign_in(user)
        get verification_link
        expect(user.email_authorizations.last.verified_at)
          .to be_within(1.minute)
          .of Time.current
      end
    end

    context "when interacting via ajax" do
      it "returns not found for non existing users" do
        expect do
          post verify_email_ownership_admin_user_path(9999), params: { user_id: user.id }, xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the email if an error occurs", :aggregate_failures do
        allow(VerificationMailer).to receive(:with).with(user_id: user.id.to_s).and_return(mailer)
        allow(mailer).to receive(:account_ownership_verification_email).and_return(message_delivery)
        allow(message_delivery).to receive(:deliver_now).and_return(false)

        assert_no_emails do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true
        end

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("failed")
      end

      it "sends an email", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")
      end

      it "allows a user to verify email ownership", :aggregate_failures do
        post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true

        path = verify_email_authorizations_path(
          confirmation_token: user.email_authorizations.first.confirmation_token,
          username: user.username,
        )
        verification_link = app_url(path)

        email = ActionMailer::Base.deliveries.last
        expect(email.subject).to eq("Verify Your #{Settings::Community.community_name} Account Ownership")
        expect(email.text_part.body).to include(verification_link)

        sign_in(user)
        get verification_link
        expect(user.email_authorizations.last.verified_at)
          .to be_within(1.minute)
          .of Time.current
      end
    end
  end

  describe "POST /admin/member_manager/users/:id/unpublish_all_articles" do
    let(:target_user) { create(:user) }
    let!(:target_articles) { create_list(:article, 3, user: target_user, published: true) }
    let!(:target_comments) { create_list(:comment, 3, user: target_user) }

    it "creates a corresponding note if note content passed" do
      text = "The articles were not interesting"
      expect do
        post unpublish_all_articles_admin_user_path(target_user.id, note: { content: text })
      end.to change(Note, :count).by(1)
      note = target_user.notes.last
      expect(note.content).to eq(text)
      expect(note.reason).to eq("unpublish_all_articles")
      expect(note.author_id).to eq(admin.id)
    end

    it "unpublishes all articles" do
      allow(Moderator::UnpublishAllArticlesWorker).to receive(:perform_async)
      post unpublish_all_articles_admin_user_path(target_user.id)
      expect(Moderator::UnpublishAllArticlesWorker).to have_received(:perform_async).with(target_user.id, admin.id,
                                                                                          "moderator")
    end

    it "unpublishes users comments and posts" do
      # User's articles are published and comments exist
      expect(target_articles.map(&:published?)).to match_array([true, true, true])
      expect(target_comments.map(&:deleted)).to match_array([false, false, false])

      sidekiq_perform_enqueued_jobs(only: Moderator::UnpublishAllArticlesWorker) do
        post unpublish_all_articles_admin_user_path(target_user.id)
      end

      # Ensure article's aren't published and comments deleted
      # (with boolean attribute so they can be reverted if needed)
      expect(target_articles.map(&:reload).map(&:published?)).to match_array([false, false, false])
      expect(target_comments.map(&:reload).map(&:deleted)).to match_array([true, true, true])
    end

    it "creates a log record" do
      Audit::Subscribe.listen :moderator

      create(:article, user: target_user, published: false)
      create(:comment, user: target_user, deleted: true)

      expect do
        sidekiq_perform_enqueued_jobs(only: Moderator::UnpublishAllArticlesWorker) do
          post unpublish_all_articles_admin_user_path(target_user.id)
        end
      end.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
      expect(log.data["action"]).to eq("unpublish_all_articles")
      expect(log.user_id).to eq(admin.id)

      # These ids match the affected articles/comments and not the ones created above
      expect(log.data["target_article_ids"]).to match_array(target_articles.map(&:id))
      expect(log.data["target_comment_ids"]).to match_array(target_comments.map(&:id))

      Audit::Subscribe.forget :moderator
    end
  end

  describe "DELETE /admin/member_manager/users/:id/remove_identity" do
    let(:provider) { Authentication::Providers.available.first }
    let(:user) do
      omniauth_mock_providers_payload
      create(:user, :with_identity)
    end

    before do
      omniauth_mock_providers_payload
      allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    end

    it "removes the given identity" do
      identity = user.identities.first

      delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }

      expect { identity.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "updates their social account's username to nil" do
      identity = user.identities.first

      delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }

      expect(user.public_send("#{identity.provider}_username")).to be_nil
    end

    it "does not remove GitHub repositories if the removed identity is not GitHub" do
      create(:github_repo, user: user)

      identity = user.identities.twitter.first

      expect do
        delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }
      end.not_to change(user.github_repos, :count)
    end

    it "removes GitHub repositories if the removed identity is GitHub" do
      repo = create(:github_repo, user: user)

      identity = user.identities.github.first

      expect do
        delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }
      end.to change(user.github_repos, :count).by(-1)

      expect(GithubRepo.exists?(id: repo.id)).to be(false)
    end
  end

  describe "PATCH admin/users/:id/unlock_access" do
    it "unlocks a locked user account" do
      user.lock_access!
      expect do
        patch unlock_access_admin_user_path(user)
      end.to change { user.reload.access_locked? }.from(true).to(false)
    end
  end

  describe "POST /admin/member_manager/users/:id/export_data" do
    it "redirects properly to the user edit page" do
      sign_in admin
      post export_data_admin_user_path(user), params: { send_to_admin: "true" }
      expect(response).to redirect_to admin_user_path(user)
    end
  end
end
