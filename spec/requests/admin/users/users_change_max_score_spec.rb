require "rails_helper"

RSpec.describe "/admin/member_manager/users" do
  let!(:user) { create(:user) }
  let!(:admin) { create(:user, :super_admin) }

  before do
    sign_in(admin)
  end

  describe "PATCH /admin/member_manager/users/:id/max_score" do
    let(:new_max_score) { 500 }
    let(:note_content) { "Increased due to high performance" }

    it "updates the user's max score" do
      patch max_score_admin_user_path(user.id), params: {
        user: {
          max_score: new_max_score,
          new_note: note_content
        }
      }

      user.reload
      expect(user.max_score).to eq(new_max_score)
      expect(flash[:success]).to be_present
    end

    it "creates a note with the reason for the change" do
      expect do
        patch max_score_admin_user_path(user.id), params: {
          user: {
            max_score: new_max_score,
            new_note: note_content
          }
        }
      end.to change(Note, :count).by(1)

      note = Note.last
      expect(note.content).to include("Changed user's maximum score to #{new_max_score}")
      expect(note.content).to include("Reason: #{note_content}")
      expect(note.reason).to eq("max_score_change")
      expect(note.author_id).to eq(admin.id)
      expect(note.noteable_id).to eq(user.id)
    end

    it "redirects to the user admin page" do
      patch max_score_admin_user_path(user.id), params: {
        user: {
          max_score: new_max_score,
          new_note: ""
        }
      }

      expect(response).to redirect_to(admin_user_path(user))
    end

    context "when the update fails" do
      let(:invalid_max_score) { -2 }

      it "sets a flash error message" do
        patch max_score_admin_user_path(user.id), params: {
          user: {
            max_score: invalid_max_score,
            new_note: note_content
          }
        }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(admin_user_path(user))
      end
    end
  end
end
