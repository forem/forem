# spec/requests/admin/emails_controller_spec.rb

require 'rails_helper'

RSpec.describe "/admin/content_manager/emails" do
  let(:admin_user) { create(:user, :admin) }
  let(:audience_segment) { create(:audience_segment) }

  before do
    # Sign in as admin user
    sign_in admin_user
  end

  describe "GET /admin/emails" do
    it "renders the index template and displays emails" do
      email1 = create(:email, subject: "First Email")
      email2 = create(:email, subject: "Second Email")
      get admin_emails_path
      expect(response.body).to include("First Email", "Second Email")
    end
  end

  describe "GET /admin/emails/new" do
    it "renders the new template with a form" do
      get new_admin_email_path
      expect(response.body).to include('name="subject"', 'name="body"', 'name="audience_segment_id"')
    end
  end

  describe "POST /admin/emails" do
    context "with valid parameters" do
      it "creates a new email and redirects to its page" do
        valid_attributes = {
          subject: "Test Subject",
          body: "Test Body",
          audience_segment_id: audience_segment.id
        }
        expect {
          post admin_emails_path, params: valid_attributes
        }.to change(Email, :count).by(1)
        expect(response).to redirect_to(admin_email_path(Email.last))
        follow_redirect!
        expect(flash[:success]).to eq(I18n.t("admin.emails_controller.created"))
      end
    end

    context "with invalid parameters" do
      it "does not create a new email and re-renders the new template" do
        invalid_attributes = {
          subject: "",
          body: "",
          audience_segment_id: nil
        }
        expect {
          post admin_emails_path, params: invalid_attributes
        }.not_to change(Email, :count)
        expect(response.body).to include(">Subject can&#39;t be blank")
        expect(flash[:danger]).to be_present
      end
    end
  end

  describe "GET /admin/emails/:id" do
    it "renders the show template for the email and replaces merge tags" do
      admin_user.update_column(:name, "Simple Admin Name")
      email = create(
        :email,
        subject: "Hello *|name|*",
        body: "<p>Dear *|name|*, welcome to our service.</p>"
      )

      get admin_email_path(email)

      # Ensure the response is successful
      expect(response).to have_http_status(:ok)

      # Check that the merge tags in the subject are replaced
      expect(response.body).to include("Hello #{admin_user.name}")

      # Check that the merge tags in the body are replaced
      expect(response.body).to include("<p>Dear #{admin_user.name}, welcome to our service.</p>")

      # Optionally, check that the raw subject and body still contain the merge tags
      expect(response.body).to include CGI.escapeHTML(email.subject)
      expect(response.body).to include CGI.escapeHTML(email.body)
    end
  end
end
