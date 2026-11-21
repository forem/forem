require "rails_helper"

RSpec.describe "/admin/member_manager/users" do
  let(:user) { create(:user) }
  let(:github_user) do
    omniauth_mock_github_payload
    create(:user, :with_identity, identities: ["github"])
  end
  let(:admin) { create(:user, :super_admin) }

  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    super
  end

  before do
    sign_in(admin)
  end

  describe "GET /admin/member_manager/users" do
    it "renders the users index without querying roles separately for each user displayed", :aggregate_failures do
      username = user.username
      create(:user)
      scoped_role_queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        sql = payload[:sql]
        scoped_role_queries << sql if sql.match?(/FROM "roles".*"users_roles".*"users_roles"\."user_id" =/)
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { get admin_users_path }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(username)
      expect(scoped_role_queries).to be_empty
    end

    context "when searching" do
      it "finds the proper user by GitHub username" do
        get "#{admin_users_path}?search=#{github_user.github_username}"
        expect(response.body).to include(CGI.escapeHTML(github_user.github_username))
      end
    end

    context "when filtering by role" do
      it "filters and shows the proper user(s)" do
        get "#{admin_users_path}?search&role=super_admin"
        expect(response.body).to include(CGI.escapeHTML(admin.name))
      end
    end

    context "when filters are applied" do
      def filter_indicator
        Nokogiri::HTML(response.body).at_css(".js-open-filter-modal-btn .c-indicator")
      end

      it "displays a filter count badge matching the number of applied filters", :aggregate_failures do
        org = create(:organization)
        expected_counts = {
          "roles[]=Super%20Admin" => "1",
          "roles[]=Super%20Admin&roles[]=Admin" => "2",
          "statuses[]=Suspended&statuses[]=Spam" => "2",
          "roles[]=Super%20Admin&statuses[]=Suspended&organizations[]=#{org.id}" => "3",
          "joining_start=01/01/2024&joining_end=31/12/2024&date_format=DD/MM/YYYY" => "1",
          "role=super_admin" => "1"
        }

        expected_counts.each do |query, count|
          get "#{admin_users_path}?#{query}"
          expect(response.body).to include("c-indicator c-indicator--info fs-xs")
          expect(filter_indicator).to be_present, "expected a filter badge for ?#{query}"
          expect(filter_indicator&.text&.strip).to eq(count), "expected badge #{count} for ?#{query}"
        end

        get admin_users_path
        expect(filter_indicator).to be_nil
      end

      it "preloads user organizations, bounds filter modal organizations, and avoids DISTINCT/N+1 queries",
         :aggregate_failures do
        stub_const("Admin::UsersController::ORGANIZATIONS_FILTER_LIMIT", 1)
        stub_const("Admin::UsersController::USERS_PER_PAGE", 1)
        org_a = create(:organization, name: "Alpha Org")
        org_z = create(:organization, name: "Zulu Org")
        create(:organization_membership, user: user, organization: org_a)
        create(:organization_membership, user: admin, organization: org_z)

        queries = []
        subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
          next if payload[:name] == "SCHEMA"

          queries << payload[:sql]
        end

        ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
          get admin_users_path, params: { organizations: [org_a.id.to_s, org_z.id.to_s] }
        end

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(CGI.escapeHTML(org_a.name), CGI.escapeHTML(org_z.name))

        per_user_org_queries = queries.select do |sql|
          sql.include?('FROM "organizations" INNER JOIN "organization_memberships"')
        end
        expect(per_user_org_queries).to be_empty

        distinct_user_queries = queries.grep(/SELECT DISTINCT "users"|COUNT\(DISTINCT "users"\."id"\)/)
        expect(distinct_user_queries).to be_empty

        bounded_count_queries = queries.grep(/SELECT COUNT\(\*\) FROM \(SELECT 1 AS one FROM "users".*LIMIT/)
        expect(bounded_count_queries.size).to eq(1)

        user_list_queries = queries.select do |sql|
          sql.include?('FROM "users"') &&
            sql.include?('FROM "organization_memberships"') &&
            sql.include?('ORDER BY "users"."created_at" DESC')
        end
        expect(user_list_queries).not_to be_empty
        expect(user_list_queries.join(" ")).not_to include('"users".*', "encrypted_password", "secret")

        org_filter_queries = queries.select { |sql| sql.include?('ORDER BY "organizations"."name" DESC') }
        expect(org_filter_queries).to all(include('SELECT "organizations"."id", "organizations"."name"'))
      end
    end
  end

  describe "GET /admin/member_manager/users/:id" do
    it "renders the overview tab with contact links, roles, banish button, flags, and reports", :aggregate_failures do
      user = github_user
      vomit = build(:reaction, category: "vomit", user_id: user.id, reactable_type: "Article", status: "valid")
      report = build(:feedback_message, category: "spam", affected_id: user.id, feedback_type: "spam", status: "Open")

      get admin_user_path(user.id)

      expect(response.body).to include(user.username)
      expect(response.body).to include("Banish user")
      expect(response.body).to include("Roles")
      expect(response.body).to include(vomit.reactable_type)
      expect(response.body).to include(report.feedback_type)

      doc = Nokogiri::HTML(response.body)

      # The primary email is rendered once, without leading whitespace, and is
      # not duplicated in the OAuth emails list.
      email_links = doc.css("a.c-link[href='mailto:#{user.email}']")
      expect(email_links.size).to eq(1)
      expect(email_links.first&.text&.strip).to eq(user.email)

      if user.github_username.present?
        github_link = doc.at_css("a.c-link--icon-left.inline-block[href='https://github.com/#{user.github_username}']")
        expect(github_link).to be_present
        expect(github_link.xpath("./text()[last()]").text.lstrip).to eq(user.github_username)
      end

      if user.twitter_username.present?
        twitter_link = doc.at_css("a.c-link--icon-left.inline-block[href='https://twitter.com/#{user.twitter_username}']")
        expect(twitter_link).to be_present
        expect(twitter_link.xpath("./text()[last()]").text.lstrip).to eq(user.twitter_username)
      end
    end

    it "displays OAuth identity emails that differ from the primary email" do
      user = github_user
      oauth_email = "github-oauth@example.com"
      omniauth_mock_github_payload
      auth = OmniAuth.config.mock_auth[:github].dup
      auth[:info][:email] = oauth_email
      identity = user.identities.first
      identity.update!(auth_data_dump: auth)

      get admin_user_path(user)

      expect(response.body).to include(oauth_email)
      expect(response.body).to include("GitHub email")
    end

    it "redirects from /username/moderate" do
      get "/#{user.username}/moderate"
      expect(response).to redirect_to(admin_user_path(user.id))
    end

    it "does not show banish button for non-admins" do
      sign_out(admin)
      expect { get admin_user_path(user.id) }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "renders subforem moderator domain (without colliding tag name) and podcast admin roles", :aggregate_failures do
      tag = create(:tag)
      subforem = create(:subforem, id: tag.id)
      podcast = create(:podcast)
      user.add_role(:subforem_moderator, subforem)
      user.add_role(:podcast_admin, podcast)

      get admin_user_path(user.id)

      expect(response).to be_successful
      expect(response.body).to include(subforem.domain, "Podcast Admin")
      expect(response.body).not_to include(tag.name)
    end

    it "displays a user's current roles in the 'Emails' tab" do
      get "#{admin_user_path(user.id)}?tab=emails"
      expect(response.body).to include("Previous emails")
    end

    it "displays password management in the 'Security' tab" do
      get "#{admin_user_path(user.id)}?tab=security"
      expect(response.body).to include("Password access")
      expect(response.body).to include("Send password reset email")
    end

    it "displays empty-state messages in the 'Flags' tab when the user has no flags", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=flags"
      expect(response.body).to include("Flags received")
      expect(response.body).to include("No flags received against")
      expect(response.body).to include("No flags received against this user&#39;s posts or comments yet.")
    end

    it "lists flags on the user's comment and article once, with mark-as-invalid action, in the 'Flags' tab",
       :aggregate_failures do
      article = create(:article, user: user, with_tags: false, with_main_image: false)
      comment = create(:comment, user: user, commentable: article)
      reaction = create(:reaction, category: "vomit", reactable: comment, user: admin, status: "valid")
      non_vomit_reaction = create(:reaction, category: "like", reactable: comment, user: user)
      article_vomit = create(:reaction, category: "vomit", reactable: article, user: admin, status: "valid")
      article_like = create(:reaction, category: "like", reactable: article, user: user)

      get "#{admin_user_path(user.id)}?tab=flags"

      expect(response.body).to include("Flags on posts and comments")
      expect(response.body).to include(CGI.escapeHTML("Comment on \"#{article.title}\""))
      expect(response.body).to include(comment.path)
      expect(response.body).to include(admin_reaction_path(reaction.id))
      expect(response.body).not_to include(admin_reaction_path(non_vomit_reaction.id))
      expect(response.body).to include(CGI.escapeHTML("Post \"#{article.title}\""))
      expect(response.body).to include(article.path)
      expect(response.body).to include(admin_reaction_path(article_vomit.id))
      expect(response.body).not_to include(admin_reaction_path(article_like.id))
      expect(response.body).to include("Mark as Invalid")
      # The flag dropdown script is included only once when both flag lists render
      expect(response.body.scan("flagReactionItemDropdownButton").size).to eq(1)
      # Content flags are not listed in the account flags section
      expect(response.body).to include("No flags received against this user yet.")
    end

    it "displays a user's current reports and the empty-state message in the 'Reports' tab", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=reports"
      expect(response.body).to include("Reports submitted by")
      expect(response.body).to include("No comment or post has been reported yet.")
    end

    it "renders empty state and displays unpublished and republished posts on unpublish_alls tab",
       :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=unpublish_logs"
      expect(response).to be_successful
      expect(response.body).not_to include("Unpublished by")

      unpublished_article = create(:article, user: user, published: false, with_tags: false, with_main_image: false)
      republished_article = create(:article, user: user, published: true, with_tags: false, with_main_image: false)
      create(:audit_log, user: admin, slug: "unpublish_all_articles",
                         data: { target_article_ids: [unpublished_article.id, republished_article.id],
                                 target_user_id: user.id })

      get "#{admin_user_path(user.id)}?tab=unpublish_logs"
      expect(response.body).to include("Unpublished by")
      expect(response.body).to include(CGI.escapeHTML(unpublished_article.title))
      expect(response.body).to include(CGI.escapeHTML(republished_article.title))
      expect(response.body).to include("(was republished)")
    end

    it "does not execute queries for inactive tabs when rendering the overview tab", :aggregate_failures do
      user.id
      inactive_tab_queries = []
      subscriber = lambda do |_name, _started, _finished, _unique_id, payload|
        next if payload[:name] == "SCHEMA"

        sql = payload[:sql]
        if sql.match?(/FROM "(?:feedback_messages|reactions|notes|email_authorizations)"/) ||
            sql.match?(/SELECT "articles"|SELECT "comments"/)
          inactive_tab_queries << sql
        end
      end

      ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
        get admin_user_path(user.id)
      end

      expect(response).to have_http_status(:ok)
      expect(inactive_tab_queries).to be_empty
    end

    it "bounds and trims columns when rendering the 'Articles' and 'Comments' tabs", :aggregate_failures do
      article = create(:article, user: user, published: true, title: "Scoped Admin Post")
      comment = create(:comment, user: user, commentable: article, body_markdown: "Scoped Admin Comment")

      article_queries = []
      ActiveSupport::Notifications.subscribed(
        lambda { |*, payload|
          sql = payload[:sql]
          article_queries << sql if sql.include?('FROM "articles"') && sql.exclude?("COUNT(*)")
        },
        "sql.active_record",
      ) do
        get "#{admin_user_path(user.id)}?tab=articles"
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Scoped Admin Post")
      expect(article_queries).not_to be_empty
      expect(article_queries).to all(include("LIMIT"))
      expected_article_select =
        'SELECT "articles"."id", "articles"."title", "articles"."path", ' \
        '"articles"."published_at", "articles"."created_at"'
      expect(article_queries).to include(a_string_including(expected_article_select))
      expect(article_queries.join(" ")).not_to include('"articles".*')
      expect(article_queries.join(" ")).not_to include("body_markdown")

      comment_queries = []
      ActiveSupport::Notifications.subscribed(
        lambda { |*, payload|
          sql = payload[:sql]
          comment_queries << sql if sql.include?('FROM "comments"') && sql.exclude?("COUNT(*)")
        },
        "sql.active_record",
      ) do
        get "#{admin_user_path(user.id)}?tab=comments"
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Scoped Admin Comment")
      expect(response.body).to include(comment.path)
      expect(comment_queries).not_to be_empty
      expect(comment_queries).to all(include("LIMIT"))
      expect(comment_queries).to include(
        a_string_including(
          'SELECT "comments"."id", "comments"."user_id", "comments"."body_markdown", "comments"."created_at"',
        ),
      )
      expect(comment_queries.join(" ")).not_to include('"comments".*')
      expect(comment_queries.join(" ")).not_to include("processed_html")
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

  describe "POST /admin/member_manager/users/:id/send_email_confirmation" do
    let(:user) { create(:user) }
    let(:message_delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
    end

    context "when interacting via a browser" do
      it "returns not found for non-existing users" do
        expect do
          post send_email_confirmation_admin_user_path(9999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the confirmation email if an error occurs" do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        allow(user).to receive(:send_confirmation_instructions).and_return(false)

        post send_email_confirmation_admin_user_path(user)

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:danger]).to include("failed")
      end

      it "sends the confirmation email successfully" do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        allow(user).to receive(:send_confirmation_instructions).and_return(true)

        post send_email_confirmation_admin_user_path(user)

        expect(response).to redirect_to(admin_user_path(user))
        expect(flash[:success]).to include("sent")
      end
    end

    context "when interacting via AJAX" do
      it "returns not found for non-existing users" do
        expect do
          post send_email_confirmation_admin_user_path(9999), xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "fails sending the confirmation email if an error occurs" do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        allow(user).to receive(:send_confirmation_instructions).and_return(false)

        post send_email_confirmation_admin_user_path(user), xhr: true

        expect(response).to have_http_status(:service_unavailable)
        expect(response.parsed_body["error"]).to include("failed")
      end

      it "sends the confirmation email successfully" do
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
        allow(user).to receive(:send_confirmation_instructions).and_return(true)

        post send_email_confirmation_admin_user_path(user), xhr: true

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")
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
          post verify_email_ownership_admin_user_path(9999)
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

      it "sends an email and allows a user to verify email ownership", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }
        end

        expect(response).to redirect_to(admin_user_path)
        expect(flash[:success]).to include("sent")

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
          post verify_email_ownership_admin_user_path(9999), xhr: true
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

      it "sends an email and allows a user to verify email ownership", :aggregate_failures do
        assert_emails(1) do
          post verify_email_ownership_admin_user_path(user), params: { user_id: user.id }, xhr: true
        end

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to include("sent")

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
    let(:target_articles) { create_list(:article, 2, user: target_user, published: true, with_tags: false) }
    let(:other_article) { create(:article, user: admin, published: true, with_tags: false) }
    let(:target_comments) do
      [*target_articles, other_article].map do |article|
        create(:comment, user: target_user, commentable: article)
      end
    end

    it "enqueues UnpublishAllArticlesWorker and creates a corresponding note when content is passed",
       :aggregate_failures do
      allow(Moderator::UnpublishAllArticlesWorker).to receive(:perform_async)
      text = "The articles were not interesting"

      expect do
        post unpublish_all_articles_admin_user_path(target_user.id, note: { content: text })
      end.to change(Note, :count).by(1)

      expect(Moderator::UnpublishAllArticlesWorker).to have_received(:perform_async).with(
        target_user.id, admin.id, "moderator"
      )
      note = target_user.notes.last
      expect(note.content).to eq(text)
      expect(note.reason).to eq("unpublish_all_articles")
      expect(note.author_id).to eq(admin.id)
    end

    it "unpublishes user's comments and posts and creates an audit log record", :aggregate_failures do
      Audit::Subscribe.listen :moderator

      expect(target_articles.map(&:published?)).to contain_exactly(true, true)
      expect(target_comments.map(&:deleted)).to contain_exactly(false, false, false)
      create(:article, user: target_user, published: false, with_tags: false)
      create(:comment, user: target_user, commentable: target_articles.first, deleted: true)

      expect do
        sidekiq_perform_enqueued_jobs(only: Moderator::UnpublishAllArticlesWorker) do
          post unpublish_all_articles_admin_user_path(target_user.id)
        end
      end.to change(AuditLog, :count).by(1)

      expect(target_articles.map { |a| a.reload.published? }).to contain_exactly(false, false)
      expect(target_comments.map { |c| c.reload.deleted? }).to contain_exactly(true, true, true)

      log = AuditLog.last
      expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
      expect(log.data["action"]).to eq("unpublish_all_articles")
      expect(log.user_id).to eq(admin.id)
      expect(log.data["target_article_ids"]).to match_array(target_articles.map(&:id))
      expect(log.data["target_comment_ids"]).to match_array(target_comments.map(&:id))
    ensure
      Audit::Subscribe.forget :moderator
    end
  end

  describe "PATCH /admin/member_manager/users/:id/update_email" do
    it "returns not found for non-existing users" do
      expect do
        patch update_email_admin_user_path(9999), params: { user: { email: "new@example.com" } }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "updates the user's email bypassing Devise reconfirmation and records an audit note", :aggregate_failures do
      old_email = user.email

      expect do
        patch update_email_admin_user_path(user), params: { user: { email: "updated@example.com" } }
      end.to change(Note, :count).by(1)

      expect(response).to redirect_to(admin_user_path(user))
      expect(flash[:success]).to be_present

      user.reload
      expect(user.email).to eq("updated@example.com")
      expect(user.unconfirmed_email).to be_nil

      note = user.notes.last
      expect(note.reason).to eq("Update Email")
      expect(note.content).to include(old_email)
      expect(note.content).to include("updated@example.com")
      expect(note.author_id).to eq(admin.id)
    end

    # update_columns bypasses the Trackable after_commit, so the controller
    # must emit explicitly or Core never learns the new address.
    it "emits user_updated to the DEV -> Core sync" do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
      Settings::General.customerio_cdp_enabled = true
      FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[user])

      with_trackable_events do
        patch update_email_admin_user_path(user), params: { user: { email: "updated@example.com" } }
      end

      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_updated", [user.id], hash_including("email" => "updated@example.com"), anything)
    ensure
      FeatureFlag.remove(:dev_core_user_sync)
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

    it "removes the given identity and updates their social account's username to nil", :aggregate_failures do
      identity = user.identities.first

      delete remove_identity_admin_user_path(user.id), params: { user: { identity_id: identity.id } }

      expect { identity.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(user.public_send(:"#{identity.provider}_username")).to be_nil
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

  describe "POST /admin/member_manager/users/:id/confirm_email" do
    let(:unconfirmed_user) { create(:user, confirmed_at: nil) }

    context "when interacting via a browser" do
      it "returns not found for non-existing users" do
        expect do
          post confirm_email_admin_user_path(9999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "confirms the user successfully and creates an audit note", :aggregate_failures do
        expect(unconfirmed_user.confirmed?).to be(false)

        expect do
          post confirm_email_admin_user_path(unconfirmed_user)
        end.to change(Note, :count).by(1)

        expect(unconfirmed_user.reload.confirmed?).to be(true)
        expect(response).to redirect_to(admin_user_path(unconfirmed_user))
        expect(flash[:success]).to be_present

        note = unconfirmed_user.notes.last
        expect(note.reason).to eq("email_confirmed")
        expect(note.content).to include("manually confirmed by #{admin.username}")
        expect(note.author_id).to eq(admin.id)
      end

      it "handles already confirmed users gracefully" do
        confirmed_user = create(:user, confirmed_at: Time.current)

        post confirm_email_admin_user_path(confirmed_user)

        expect(response).to redirect_to(admin_user_path(confirmed_user))
      end
    end

    context "when interacting via AJAX" do
      it "returns not found for non-existing users" do
        expect do
          post confirm_email_admin_user_path(9999), xhr: true
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "confirms the user successfully and creates an audit note via AJAX", :aggregate_failures do
        expect(unconfirmed_user.confirmed?).to be(false)

        expect do
          post confirm_email_admin_user_path(unconfirmed_user), xhr: true
        end.to change(Note, :count).by(1)

        expect(unconfirmed_user.reload.confirmed?).to be(true)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to be_present

        note = unconfirmed_user.notes.last
        expect(note.reason).to eq("email_confirmed")
        expect(note.content).to include("manually confirmed by #{admin.username}")
      end
    end
  end

  describe "POST /admin/member_manager/users/:id/confirm_pending_email" do
    let(:user_with_pending_email) do
      u = create(:user, confirmed_at: Time.current)
      u.update_columns(unconfirmed_email: "newemail@example.com")
      u
    end

    context "when interacting via a browser" do
      it "returns not found for non-existing users" do
        expect do
          post confirm_pending_email_admin_user_path(9999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "confirms the pending email change successfully and creates an audit note", :aggregate_failures do
        old_email = user_with_pending_email.email

        expect do
          post confirm_pending_email_admin_user_path(user_with_pending_email)
        end.to change(Note, :count).by(1)

        user_with_pending_email.reload
        expect(user_with_pending_email.email).to eq("newemail@example.com")
        expect(user_with_pending_email.unconfirmed_email).to be_nil
        expect(user_with_pending_email.confirmed_at).to be_present
        expect(response).to redirect_to(admin_user_path(user_with_pending_email))
        expect(flash[:success]).to be_present

        note = user_with_pending_email.notes.last
        expect(note.reason).to eq("pending_email_confirmed")
        expect(note.content).to include(old_email)
        expect(note.content).to include("newemail@example.com")
        expect(note.author_id).to eq(admin.id)
      end

      # update_columns bypasses the Trackable after_commit, so the controller
      # must emit explicitly or Core never learns the swapped address.
      it "emits user_updated to the DEV -> Core sync" do
        allow(Trackable::Registry).to receive(:active_names).and_return([:any])
        allow(Trackable::DispatchWorker).to receive(:perform_async)
        Settings::General.customerio_cdp_enabled = true
        FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[user_with_pending_email])

        with_trackable_events do
          post confirm_pending_email_admin_user_path(user_with_pending_email)
        end

        expect(Trackable::DispatchWorker).to have_received(:perform_async)
          .with(anything, "user_updated", [user_with_pending_email.id],
                hash_including("email" => "newemail@example.com"), anything)
      ensure
        FeatureFlag.remove(:dev_core_user_sync)
      end

      it "fails gracefully when there is no pending email" do
        user_without_pending = create(:user, confirmed_at: Time.current)

        post confirm_pending_email_admin_user_path(user_without_pending)

        expect(flash[:danger]).to be_present
      end
    end

    context "when interacting via AJAX" do
      it "confirms the pending email change successfully" do
        post confirm_pending_email_admin_user_path(user_with_pending_email), xhr: true

        user_with_pending_email.reload
        expect(user_with_pending_email.email).to eq("newemail@example.com")
        expect(user_with_pending_email.unconfirmed_email).to be_nil
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["result"]).to be_present
      end
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

  describe "audit log creation" do
    before { Audit::Subscribe.listen :moderator }

    after { Audit::Subscribe.forget :moderator }

    def expect_moderator_log(action, **expected_data)
      log = AuditLog.last
      expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
      expect(log.user_id).to eq(admin.id)
      expect(log.data).to include("action" => action, "target_user_id" => user.id, **expected_data.stringify_keys)
    end

    it "creates audit log records for email, profile, reputation, and max_score actions", :aggregate_failures do
      expect do
        patch update_email_admin_user_path(user), params: { user: { email: "audit@example.com" } }
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("update_email", new_email: "audit@example.com")

      expect do
        patch update_profile_admin_user_path(user), params: { user: { name: "New Name" } }
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("update_profile", changes: be_present)

      user.update_columns(unconfirmed_email: "pending@example.com")
      expect do
        post confirm_pending_email_admin_user_path(user)
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("confirm_pending_email", new_email: "pending@example.com")

      expect do
        patch reputation_modifier_admin_user_path(user), params: { user: { reputation_modifier: 2.0 } }
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("reputation_modifier")

      expect do
        patch max_score_admin_user_path(user), params: { user: { max_score: 50 } }
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("max_score")

      user.update_columns(confirmed_at: nil)
      expect do
        post confirm_email_admin_user_path(user)
      end.to change(AuditLog, :count).by(1)
      expect_moderator_log("confirm_email")
    end

    describe "DELETE /admin/member_manager/users/:id/remove_identity" do
      it "creates an audit log record" do
        omniauth_mock_providers_payload
        allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
        identity_user = create(:user, :with_identity, uid: rand(1_000_000).to_s)
        identity = identity_user.identities.first

        expect do
          delete remove_identity_admin_user_path(identity_user.id),
                 params: { user: { identity_id: identity.id } }
        end.to change(AuditLog, :count).by(1)

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.data["action"]).to eq("remove_identity")
        expect(log.data["target_user_id"]).to eq(identity_user.id)
        expect(log.data["provider"]).to eq(identity.provider)
      end
    end

    describe "PATCH /admin/member_manager/users/:id/update_password" do
      it "creates an audit log record without logging sensitive password parameters" do
        expect do
          patch update_password_admin_user_path(user.id), params: {
            user: { password: "new-password-123", password_confirmation: "new-password-123" }
          }
        end.to change(AuditLog, :count).by(1)

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.data["action"]).to eq("update_password")
        expect(log.data["target_user_id"]).to eq(user.id)
        expect(log.data.to_s).not_to include("new-password-123")
      end
    end

    describe "POST /admin/member_manager/users/:id/send_password_reset" do
      it "creates an audit log record" do
        expect do
          post send_password_reset_admin_user_path(user.id)
        end.to change(AuditLog, :count).by(1)

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::MODERATOR_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.data["action"]).to eq("send_password_reset")
        expect(log.data["target_user_id"]).to eq(user.id)
      end
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=audit_log" do
    it "displays the empty state and filters audit logs by default (by_user), filter=by_user, and filter=on_user",
       :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=audit_log"
      expect(response).to be_successful
      expect(response.body).to include("Audit Log")
      expect(response.body).to include("No audit log entries found")

      create(:audit_log, user: user, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY,
                         slug: "test_actor_action", data: { "action" => "test_actor_action" })
      create(:audit_log, user: admin, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY,
                         slug: "user_status",
                         data: { "action" => "user_status", "target_user_id" => user.id })

      get "#{admin_user_path(user.id)}?tab=audit_log"
      expect(response.body).to include("Test actor action")
      expect(response.body).not_to include("User status")

      get "#{admin_user_path(user.id)}?tab=audit_log&filter=by_user"
      expect(response.body).to include("Test actor action")
      expect(response.body).not_to include("User status")

      get "#{admin_user_path(user.id)}?tab=audit_log&filter=on_user"
      expect(response.body).to include("User status")
      expect(response.body).not_to include("Test actor action")
    end

    it "paginates audit logs" do
      now = Time.current
      AuditLog.insert_all(
        Array.new(26) do
          { user_id: user.id, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY,
            slug: "test", data: { "action" => "test" }, created_at: now, updated_at: now }
        end,
      )
      get "#{admin_user_path(user.id)}?tab=audit_log"
      expect(response.body).to include("Next")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=identities" do
    it "displays the identities tab with user's identities and an empty message when none exist",
       :aggregate_failures do
      user = github_user
      identity = user.identities.first
      get "#{admin_user_path(user.id)}?tab=identities"
      expect(response).to be_successful
      expect(response.body).to include("Connected Auth Identities")
      expect(response.body).to include(identity.uid)
      expect(response.body).to include("GitHub")

      user.identities.destroy_all
      get "#{admin_user_path(user.id)}?tab=identities"
      expect(response).to be_successful
      expect(response.body).to include("No auth identities associated with this user.")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=badges" do
    it "displays an empty message and renders user's badge achievements when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=badges"
      expect(response).to be_successful
      expect(response.body).to include("No badges earned or awarded yet.")

      badge = create(:badge, title: "Super Contributor", description: "Awarded for amazing work")
      create(:badge_achievement, user: user, badge: badge, rewarder: admin)
      get "#{admin_user_path(user.id)}?tab=badges"
      expect(response).to be_successful
      expect(response.body).to include("Badges &amp; Achievements")
      expect(response.body).to include("Super Contributor")
      expect(response.body).to include("Awarded for amazing work")
      expect(response.body).to include(CGI.escapeHTML(admin.name))
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=reactions" do
    it "displays an empty message and renders user's reactions when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=reactions"
      expect(response).to be_successful
      expect(response.body).to include("No reactions found for this user.")

      article = create(:article, title: "Fascinating Post", with_tags: false)
      create(:reaction, user: user, reactable: article, category: "like", status: "valid")
      get "#{admin_user_path(user.id)}?tab=reactions"
      expect(response).to be_successful
      expect(response.body).to include("User Reactions")
      expect(response.body).to include("Like")
      expect(response.body).to include("Fascinating Post")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=agent_sessions" do
    it "displays an empty message and renders user's agent sessions when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=agent_sessions"
      expect(response).to be_successful
      expect(response.body).to include("No agent sessions found for this user.")

      create(:agent_session, user: user, title: "Refactoring Auth Module", tool_name: "claude_code", published: true)
      get "#{admin_user_path(user.id)}?tab=agent_sessions"
      expect(response).to be_successful
      expect(response.body).to include("Agent Sessions")
      expect(response.body).to include("Refactoring Auth Module")
      expect(response.body).to include("Claude Code")
      expect(response.body).to include("Published")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=collections" do
    it "displays an empty message and renders user's series and collections when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=collections"
      expect(response).to be_successful
      expect(response.body).to include("No series or collections found for this user.")

      create(:collection, user: user, title: "Complete Rails Guide", description: "All parts of the guide")
      get "#{admin_user_path(user.id)}?tab=collections"
      expect(response).to be_successful
      expect(response.body).to include("Series &amp; Collections")
      expect(response.body).to include("Complete Rails Guide")
      expect(response.body).to include("All parts of the guide")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=follows" do
    let(:other_user) { create(:user, name: "Followed Friend") }

    it "displays an empty message and renders followers and following when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=follows"
      expect(response).to be_successful
      expect(response.body).to include("No follows found.")

      create(:follow, follower: other_user, followable: user)
      get "#{admin_user_path(user.id)}?tab=follows"
      expect(response).to be_successful
      expect(response.body).to include("Follows &amp; Followers")
      expect(response.body).to include("Followed Friend")

      create(:follow, follower: user, followable: other_user)
      get "#{admin_user_path(user.id)}?tab=follows&filter=following"
      expect(response).to be_successful
      expect(response.body).to include("Followed Friend")
    end
  end

  describe "GET /admin/member_manager/users/:id?tab=blocks" do
    let(:blocked_user) { create(:user, name: "Blocked Spammer") }

    it "displays an empty message and renders user blocks when present", :aggregate_failures do
      get "#{admin_user_path(user.id)}?tab=blocks"
      expect(response).to be_successful
      expect(response.body).to include("No user blocks found.")

      UserBlock.create!(blocker: user, blocked: blocked_user, config: "default")
      get "#{admin_user_path(user.id)}?tab=blocks"
      expect(response).to be_successful
      expect(response.body).to include("User Blocks")
      expect(response.body).to include("Blocked Spammer")

      get "#{admin_user_path(blocked_user.id)}?tab=blocks&filter=blocked_by"
      expect(response).to be_successful
      expect(response.body).to include(CGI.escapeHTML(user.name))
    end
  end
end
