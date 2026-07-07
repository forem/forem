require "rails_helper"

RSpec.describe "/admin/member_manager/users" do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "PATCH /admin/member_manager/users/:id/update_email" do
    let(:new_email) { "new_email@example.com" }

    it "updates the user's email" do
      patch update_email_admin_user_path(user.id), params: {
        user: {
          email: new_email
        }
      }

      user.reload
      expect(user.email).to eq(new_email)
      expect(flash[:success]).to be_present
    end

    it "creates a note that logs the old email and new email" do
      old_email = user.email
      expect do
        patch update_email_admin_user_path(user.id), params: {
          user: {
            email: new_email
          }
        }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.content).to include("Updated email from #{old_email} to #{new_email}")
      expect(note.reason).to eq("Update Email")
      expect(note.author_id).to eq(admin.id)
      expect(note.noteable_id).to eq(user.id)
    end

    it "redirects to the user admin page" do
      patch update_email_admin_user_path(user.id), params: {
        user: {
          email: new_email
        }
      }

      expect(response).to redirect_to(admin_user_path(user))
    end

    context "when the new email is already taken by another user" do
      let!(:other_user) { create(:user, email: "taken@example.com") }

      it "does not update the email and sets an error flash message" do
        old_email = user.email

        patch update_email_admin_user_path(user.id), params: {
          user: {
            email: "taken@example.com"
          }
        }

        user.reload
        expect(user.email).to eq(old_email)
        expect(flash[:error]).to include("Email has already been taken")
        expect(response).to redirect_to(admin_user_path(user))
      end
    end

    context "when the new email format is invalid" do
      it "does not update the email and sets an error flash message" do
        old_email = user.email

        patch update_email_admin_user_path(user.id), params: {
          user: {
            email: "invalid-email-format"
          }
        }

        user.reload
        expect(user.email).to eq(old_email)
        expect(flash[:error]).to include("Email is invalid")
        expect(response).to redirect_to(admin_user_path(user))
      end
    end
  end
end
