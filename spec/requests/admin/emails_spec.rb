# spec/requests/admin/emails_controller_spec.rb

require "rails_helper"

RSpec.describe "/admin/emails" do
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
      expect(response.body).to include('name="email[subject]"', 'name="email[body]"', 'name="email[audience_segment_id]"')
    end
  end

  describe "POST /admin/emails" do
    context "with valid parameters" do
      it "creates a new email and redirects to its page" do
        valid_attributes = {
          email: {
            subject: "Test Subject",
            body: "Test Body",
            audience_segment_id: audience_segment.id
          }
        }
        expect {
          post admin_emails_path, params: valid_attributes
        }.to change(Email, :count).by(1)
        expect(response).to redirect_to(admin_email_path(Email.last))
        follow_redirect!
        expect(flash[:success]).to eq(I18n.t("admin.emails_controller.drafted"))
      end
    end

    context "with invalid parameters" do
      it "does not create a new email and re-renders the new template" do
        invalid_attributes = {
          email: {
            subject: "",
            body: "",
            audience_segment_id: nil
          }
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

  describe "PATCH /admin/emails/:id" do
    let!(:email) { create(:email, subject: "Old Subject", body: "Old Body") }

    context "with valid parameters" do
      let(:valid_attributes) do
        {
          email: {
            subject: "Updated Subject",
            body: "Updated Body"
          }
        }
      end

      it "updates the email and redirects to its page" do
        patch admin_email_path(email), params: valid_attributes
        expect(response).to redirect_to(admin_email_path(email))
        follow_redirect!
        expect(response.body).to include("Updated Subject", "Updated Body")
        expect(flash[:success]).to eq(I18n.t("admin.emails_controller.updated"))
        email.reload
        expect(email.subject).to eq("Updated Subject")
        expect(email.body).to eq("Updated Body")
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          email: {
            subject: "",
            body: ""
          }
        }
      end

      it "does not update the email and re-renders the edit template" do
        patch admin_email_path(email), params: invalid_attributes
        expect(response.body).to include(">Subject can&#39;t be blank")
        expect(flash[:danger]).to be_present
        email.reload
        expect(email.subject).to eq("Old Subject")
        expect(email.body).to eq("Old Body")
      end
    end

    context "with test_email_addresses provided" do
      let(:valid_attributes_with_test) do
        {
          email: {
            subject: "New Subject",
            body: "New Body",
            test_email_addresses: "test@example.com,another@example.com"
          }
        }
      end

      it "calls deliver_to_test_emails" do
        expect_any_instance_of(Email).to receive(:deliver_to_test_emails).with("test@example.com,another@example.com")
        patch admin_email_path(email), params: valid_attributes_with_test
        expect(response).to redirect_to(admin_email_path(email))
        follow_redirect!
        expect(flash[:success]).to eq("Test email delivering to test@example.com,another@example.com")
      end
    end
  end
end
