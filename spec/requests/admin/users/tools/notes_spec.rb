require "rails_helper"

RSpec.describe "/admin/users/:user_id/tools/notes", type: :request do
  include_examples "Admin::Users::Tools::ShowAction", :admin_user_tools_notes_path,
                   Admin::Users::Tools::NotesComponent

  describe "#create" do
    let(:user) { create(:user) }

    it "returns not found for non existing users" do
      expect { post admin_user_tools_notes_path(9999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns :unprocessable_entity if a param is invalid", :aggregate_failures do
      expect do
        post admin_user_tools_notes_path(user), params: { note: { content: nil } }, xhr: true
      end.to not_change(user.notes, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to be_present
    end

    it "adds a note to the user", :aggregate_failures do
      expect do
        post admin_user_tools_notes_path(user), params: { note: { content: "Test" } }, xhr: true
      end.to change(user.notes, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "returns a JSON result", :aggregate_failures do
      post admin_user_tools_notes_path(user), params: { note: { content: "Test" } }, xhr: true

      expect(response.media_type).to eq("application/json")
      expect(response.parsed_body["result"]).to be_present
    end
  end
end
