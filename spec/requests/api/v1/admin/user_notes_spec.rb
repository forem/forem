require "rails_helper"

RSpec.describe "Api::V1::Admin::UserNotes" do
  before { Audit::Subscribe.listen :admin_api }
  after  { Audit::Subscribe.forget :admin_api }

  let!(:user) { create(:user) }

  describe "GET /api/admin/users/:user_id/notes" do
    it "lists notes newest first" do
      caller = create(:user, :super_admin)
      old_note = Note.create!(noteable: user, author: caller, reason: "misc_note", content: "older",
                              created_at: 2.days.ago)
      new_note = Note.create!(noteable: user, author: caller, reason: "misc_note", content: "newer",
                              created_at: 1.day.ago)

      get "/api/admin/users/#{user.id}/notes", headers: admin_api_headers

      expect(response).to have_http_status(:ok)
      ids = response.parsed_body["notes"].pluck("id")
      expect(ids).to eq([new_note.id, old_note.id])
    end

    it "returns 404 for missing user" do
      get "/api/admin/users/999999/notes", headers: admin_api_headers
      expect(response).to have_http_status(:not_found)
    end

    it "rejects unauth callers" do
      get "/api/admin/users/#{user.id}/notes",
          headers: { "Accept" => "application/vnd.forem.api-v1+json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/admin/users/:user_id/notes" do
    it "creates a note with default reason and the api caller as author" do
      caller_user = create(:user, :super_admin)
      headers = admin_api_headers(user: caller_user)

      expect do
        post "/api/admin/users/#{user.id}/notes",
             params: { content: "spotted spam pattern" }, headers: headers
      end.to change(Note, :count).by(1)

      expect(response).to have_http_status(:created)
      note = Note.last
      expect(note.noteable).to eq(user)
      expect(note.author).to eq(caller_user)
      expect(note.reason).to eq("misc_note")
      expect(note.content).to eq("spotted spam pattern")
    end

    it "accepts a custom reason" do
      post "/api/admin/users/#{user.id}/notes",
           params: { content: "x", reason: "core_sync" }, headers: admin_api_headers

      expect(response).to have_http_status(:created)
      expect(Note.last.reason).to eq("core_sync")
    end

    it "audits the creation without leaking content" do
      expect do
        post "/api/admin/users/#{user.id}/notes",
             params: { content: "secret" }, headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)

      audit = AuditLog.last
      expect(audit.slug).to eq("add_user_note")
      expect(audit.data).to include("target_user_id" => user.id, "reason" => "misc_note")
      expect(audit.data["content"]).to be_nil
    end

    it "returns 422 on missing content" do
      post "/api/admin/users/#{user.id}/notes", params: {}, headers: admin_api_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
