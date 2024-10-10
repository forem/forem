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
  end
end
