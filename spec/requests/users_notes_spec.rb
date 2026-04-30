require "rails_helper"

RSpec.describe "/admin/member_manager/users notes tab" do
  let(:admin) { create(:user, :super_admin) }
  let(:target_user) { create(:user) }

  before { sign_in(admin) }

  describe "GET /admin/member_manager/users/:id?tab=notes" do
    context "when notes exist with a valid author" do
      it "renders the notes tab without error" do
        create(:note,
               author: admin,
               noteable: target_user,
               reason: "misc_note",
               content: "This user looks suspicious.")

        get admin_user_path(target_user, tab: "notes")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("This user looks suspicious.")
      end
    end

    context "when a note has no author (nil author_id)" do
      it "renders the notes tab without raising an error" do
        create(:note,
               author: nil,
               noteable: target_user,
               reason: "misc_note",
               content: "System-generated note with no author.")

        get admin_user_path(target_user, tab: "notes")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("System-generated note with no author.")
      end

      it "displays the unknown user fallback instead of crashing" do
        create(:note,
               author: nil,
               noteable: target_user,
               reason: "misc_note",
               content: "Orphaned note content.")

        get admin_user_path(target_user, tab: "notes")

        expect(response).to have_http_status(:ok)
      end
    end

    context "when no notes exist" do
      it "renders the empty state" do
        get admin_user_path(target_user, tab: "notes")

        expect(response).to have_http_status(:ok)
      end
    end

    context "when multiple notes exist with mixed authors" do
      it "renders all notes without N+1 queries" do
        create(:note, author: admin, noteable: target_user,
               reason: "misc_note", content: "Note with author.")
        create(:note, author: nil, noteable: target_user,
               reason: "misc_note", content: "Note without author.")

        # Both notes should render without error regardless of author presence
        get admin_user_path(target_user, tab: "notes")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Note with author.")
        expect(response.body).to include("Note without author.")
      end
    end
  end
end
