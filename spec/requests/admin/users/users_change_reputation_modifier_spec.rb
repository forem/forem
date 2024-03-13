require "rails_helper"

RSpec.describe "/admin/member_manager/users" do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "PATCH /admin/member_manager/users/:id/reputation_modifier" do
    let(:new_reputation_modifier) { 1.5 }
    let(:note_content) { "Improvement in community engagement" }

    it "updates the user's reputation modifier" do
      patch reputation_modifier_admin_user_path(user.id), params: {
        user: {
          reputation_modifier: new_reputation_modifier,
          new_note: note_content
        }
      }

      user.reload
      expect(user.reputation_modifier).to eq(new_reputation_modifier)
      expect(flash[:success]).to be_present
    end

    it "creates a note with the reason for the change" do
      expect do
        patch reputation_modifier_admin_user_path(user.id), params: {
          user: {
            reputation_modifier: new_reputation_modifier,
            new_note: note_content
          }
        }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.content).to include("Changed user's reputation modifier to #{new_reputation_modifier}")
      expect(note.content).to include("Reason: #{note_content}")
      expect(note.reason).to eq("reputation_modifier_change")
      expect(note.author_id).to eq(admin.id)
      expect(note.noteable_id).to eq(user.id)
    end

    it "redirects to the user admin page" do
      patch reputation_modifier_admin_user_path(user.id), params: {
        user: {
          reputation_modifier: new_reputation_modifier,
          new_note: ""
        }
      }

      expect(response).to redirect_to(admin_user_path(user))
    end

    context "when the update fails" do
      let(:invalid_reputation_modifier) { "6" }

      it "sets a flash error message" do
        patch reputation_modifier_admin_user_path(user.id), params: {
          user: {
            reputation_modifier: invalid_reputation_modifier,
            new_note: note_content
          }
        }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(admin_user_path(user))
      end
    end
  end
end
