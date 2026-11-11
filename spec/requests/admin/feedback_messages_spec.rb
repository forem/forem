require "rails_helper"

RSpec.describe "/admin/moderation/reports" do
  let(:feedback_message)  { create(:feedback_message, :abuse_report) }
  let(:user)              { create(:user) }
  let(:trusted_user)      { create(:user, :trusted) }
  let(:admin)             { create(:user, :super_admin) }

  def collect_sql_queries(&block)
    queries = []
    callback = lambda do |*, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end

  describe "GET /admin/moderation/reports" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: FeedbackMessage) }

    context "when the user is a single resource admin" do
      it "renders with status 200" do
        sign_in single_resource_admin
        get admin_reports_path
        expect(response).to have_http_status :ok
      end
    end

    context "when there is a vomit reaction on a user with score > -150 and created in the last two weeks" do
      it "renders with status 200" do
        trusted_user
        # Assume User model has a score attribute
        user.update!(score: -100) # Ensure the user's score is greater than -150
        create(:reaction, category: "vomit", reactable: user, user: trusted_user, created_at: 1.week.ago)
        sign_in admin
        get admin_reports_path
        expect(response).to have_http_status :ok
        expect(response.body).to include("(1)")

        get flag_reactions_admin_reports_path, params: { status: "Open" }
        expect(response).to have_http_status :ok
        expect(response.body).to include(user.username)
      end

      it "does not render if the reaction is older than two weeks" do
        trusted_user
        user.update!(score: -100)
        create(:reaction, category: "vomit", reactable: user, user: trusted_user, created_at: 3.weeks.ago)
        sign_in admin
        get admin_reports_path
        expect(response.body).to include("(0)")

        get flag_reactions_admin_reports_path, params: { status: "Open" }
        expect(response).to have_http_status :ok
        expect(response.body).not_to include(user.username)
      end

      it "does not render if the reactable score is <= -150" do
        trusted_user
        user.update!(score: -200) # Ensure the user's score is less than or equal to -150
        create(:reaction, category: "vomit", reactable: user, user: trusted_user, created_at: 1.week.ago)
        sign_in admin
        get admin_reports_path
        expect(response.body).to include("(0)")

        get flag_reactions_admin_reports_path, params: { status: "Open" }
        expect(response).to have_http_status :ok
        expect(response.body).not_to include(user.username)
      end
    end

    it "escapes offender report messages in the admin view" do
      offender = create(:user)
      payload = %(<img src=x onerror="alert('xss-proof')">)
      create(:feedback_message, :abuse_report, offender: offender, message: payload)

      sign_in admin
      get admin_reports_path

      expect(response.body).to include(CGI.escapeHTML(payload))
      expect(response.body).not_to include(payload)
    end

    context "when there are more than 25 reports" do
      it "paginates the reports" do
        create_list(:feedback_message, 26, :abuse_report, status: "Open") # rubocop:disable FactoryBot/ExcessiveCreateList
        sign_in admin
        get admin_reports_path
        expect(response).to have_http_status :ok
        expect(response.body.scan(/id="accordion-\d+/).length).to eq(25)
      end
    end

    it "preloads user roles and reported comment authors without per-report N+1 queries" do
      offender = create(:user)
      reported_user = create(:user, :warned)
      article = create(:article, user: offender, main_image: nil)
      comment = create(:comment, user: offender, commentable: article)

      create(:feedback_message, :abuse_report,
             reporter: user, offender: offender, reported: reported_user,
             reported_url: "/#{reported_user.username}", status: "Open")
      create(:feedback_message, :abuse_report,
             reporter: trusted_user, offender: offender, reported: comment,
             reported_url: comment.path, status: "Open")

      sign_in admin
      queries = collect_sql_queries { get admin_reports_path }

      expect(response).to have_http_status :ok
      expect(response.body).to include("Warned")
      expect(response.body).to include(comment.path)
      expect(queries.grep(/SELECT COUNT\(\*\) FROM "roles"/)).to be_empty
    end

    it "skips the open flag reactions count query on non-Open tabs" do
      sign_in admin
      queries = collect_sql_queries { get admin_reports_path, params: { status: "Resolved" } }

      expect(response).to have_http_status :ok
      expect(queries.grep(/reactable_articles/)).to be_empty
    end
  end

  describe "GET /admin/moderation/reports/:id" do
    it "preloads user roles on the individual report view without per-role count queries" do
      offender = create(:user, :suspended)
      report = create(:feedback_message, :abuse_report, reporter: user, offender: offender, status: "Open")

      sign_in admin
      queries = collect_sql_queries { get admin_report_path(report.id) }

      expect(response).to have_http_status :ok
      expect(response.body).to include("Suspended")
      expect(queries.grep(/SELECT COUNT\(\*\) FROM "roles"/)).to be_empty
    end
  end

  describe "GET /admin/moderation/reports/flag_reactions" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: FeedbackMessage) }

    before do
      sign_in single_resource_admin
    end

    it "renders the flag reactions list template" do
      get flag_reactions_admin_reports_path
      expect(response).to have_http_status :ok
      expect(response).to render_template(partial: "admin/feedback_messages/_flag_reactions_list")
    end

    context "when there is a vomit reaction on a user with score > -125" do
      it "includes the reaction info" do
        user.update!(score: 0)
        create(:reaction, category: "vomit", reactable: user, user: trusted_user, created_at: 1.week.ago)
        get flag_reactions_admin_reports_path, params: { status: "Open" }
        expect(response.body).to include(user.username)
      end

      it "renders flagged user and comment reactions without per-row role or vomit N+1 queries" do
        flagged_user = create(:user, score: 0)
        comment_author = create(:user, score: 0)
        article = create(:article, user: comment_author, main_image: nil)
        comment = create(:comment, user: comment_author, commentable: article, score: 0)

        create(:reaction, category: "vomit", status: "valid", reactable: flagged_user,
                          user: trusted_user, created_at: 1.week.ago)
        create(:reaction, category: "vomit", status: "confirmed", reactable: flagged_user,
                          user: admin, created_at: 2.days.ago)
        create(:reaction, category: "vomit", status: "valid", reactable: comment,
                          user: trusted_user, created_at: 1.week.ago)

        queries = collect_sql_queries { get flag_reactions_admin_reports_path, params: { status: "Open" } }

        expect(response).to have_http_status :ok
        expect(response.body).to include(flagged_user.username)
        expect(response.body).to include("Flagged")
        expect(response.body).to include(comment.path)
        expect(queries.grep(/SELECT COUNT\(\*\) FROM "roles"/)).to be_empty
        expect(queries.grep(/SELECT 1 AS one FROM "reactions"/)).to be_empty
      end
    end
  end

  describe "POST /admin/moderation/reports/save_status" do
    context "when a valid request is made" do
      let(:save_status_params) do
        {
          status: "Resolved",
          id: feedback_message.id
        }
      end

      before do
        sign_in admin
      end

      it "updates the status of the feedback message and returns Success", :aggregate_failures do
        post save_status_admin_reports_path, params: save_status_params

        expect(response.parsed_body).to eq("outcome" => "Success")
        expect(FeedbackMessage.last.status).to eq("Resolved")
      end
    end
  end

  describe "POST /send_email" do
    context "when a valid request is made" do
      let(:send_email_params) do
        {
          feedback_message_id: feedback_message.id,
          email_subject: "Thank you for your report",
          email_body: "Thanks for your report and being an awesome member!",
          email_type: "reporter",
          email_to: user.email
        }
      end

      let(:email_message_attributes) do
        {
          feedback_message_id: send_email_params[:feedback_message_id],
          subject: send_email_params[:email_subject],
          to: send_email_params[:email_to]
        }.stringify_keys
      end

      before do
        sign_in admin
      end

      it "creates a new email message and returns Success", :aggregate_failures do
        allow(ForemInstance).to receive(:smtp_enabled?).and_return(true)
        post send_email_admin_reports_path, params: send_email_params

        expect(response.parsed_body).to eq("outcome" => "Success")
        expect(EmailMessage.last.attributes).to include(email_message_attributes)
      end
    end
  end

  describe "POST /admin/moderation/reports/create_note" do
    context "when a valid request is made" do
      let(:note_params) do
        {
          author_id: admin.id,
          content: "test note",
          reason: "abuse-reports",
          noteable_id: feedback_message.id,
          noteable_type: "FeedbackMessage"
        }.stringify_keys
      end

      before do
        sign_in admin
      end

      it "creates a note, queues a slack message, and renders the JSON response", :aggregate_failures do
        sidekiq_assert_enqueued_with(job: Slack::Messengers::Worker) do
          post create_note_admin_reports_path, params: note_params
        end

        expected_response = {
          outcome: "Success",
          content: "test note",
          author_name: admin.name
        }.stringify_keys
        expect(response.parsed_body).to eq(expected_response)
        expect(Note.last.attributes).to include(note_params)
      end
    end
  end
end
