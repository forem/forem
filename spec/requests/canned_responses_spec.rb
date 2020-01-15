require "rails_helper"

RSpec.describe "CannedResponses", type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :tag_moderator) }
  let(:admin) { create(:user, :admin) }

  describe "GET /canned_responses #index" do
    it "returns not found if no user is logged in" do
      expect do
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error ActiveRecord::RecordNotFound
    end

    context "when signed in as a regular user" do
      before { sign_in user }

      it "responds with JSON" do
        create(:canned_response, user: user, type_of: "personal_comment")
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
        expect(response.content_type).to eq "application/json"
      end

      it "returns an array of all the user's canned responses" do
        total_canned_responses = 2
        create(:canned_response, user: nil, type_of: "mod_comment")
        create_list(:canned_response, total_canned_responses, user: user, type_of: "personal_comment")
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq total_canned_responses
      end

      it "returns only the users' canned responses" do
        create(:canned_response, user: nil, type_of: "mod_comment")
        create_list(:canned_response, 2, user: user, type_of: "personal_comment")
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["userId"] }
        expect(user_ids).to eq [user.id, user.id]
      end

      it "raises an error if trying to view moderator canned responses" do
        create(:canned_response, user: nil, type_of: "mod_comment")
        expect do
          get "/canned_responses?type_of=mod_comment&personal_included=true", headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end

      it "raises an error if trying to view admin canned responses" do
        create(:canned_response, user: nil, type_of: "email_reply")
        expect do
          get "/canned_responses?type_of=email_reply", headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as a mod user" do
      before { sign_in moderator }

      let(:url) { "/canned_responses?type_of=mod_comment&personal_included=true" }

      it "responds with JSON" do
        create(:canned_response, user: moderator, type_of: "personal_comment")
        get url, headers: { HTTP_ACCEPT: "application/json" }
        expect(response.content_type).to eq "application/json"
      end

      it "returns an array of all relevant canned responses" do
        create_list(:canned_response, 2, user: nil, type_of: "mod_comment")
        create_list(:canned_response, 2, user: moderator, type_of: "personal_comment")
        get url, headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq 4
      end

      it "returns only the moderator and personal canned responses with the correct params" do
        create_list(:canned_response, 2, user: nil, type_of: "mod_comment")
        create_list(:canned_response, 2, user: moderator, type_of: "personal_comment")

        get url, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["userId"] }
        expect(user_ids).to eq [nil, nil, moderator.id, moderator.id]
      end

      it "returns the user's canned responses when no params are given" do
        create_list(:canned_response, 2, user: moderator, type_of: "personal_comment")
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["userId"] }
        expect(user_ids).to eq [moderator.id, moderator.id]
      end

      it "raises unauthorized error if trying to view admin canned responses" do
        create_list(:canned_response, 2, user: nil, type_of: "email_reply")
        expect do
          get "/canned_responses?type_of=email_reply", headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as an admin" do
      before { sign_in admin }

      it "returns only the moderator and personal canned responses with the correct params" do
        create_list(:canned_response, 2, user: nil, type_of: "mod_comment")
        create_list(:canned_response, 2, user: admin, type_of: "personal_comment")

        get "/canned_responses?type_of=mod_comment&personal_included=true", headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["userId"] }
        expect(user_ids).to eq [nil, nil, admin.id, admin.id]
      end

      it "returns the user's canned responses" do
        create_list(:canned_response, 2, user: admin, type_of: "personal_comment")
        get "/canned_responses", headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["userId"] }
        expect(user_ids).to eq [admin.id, admin.id]
      end

      it "allows access and returns an array of admin level canned responses" do
        create_list(:canned_response, 2, user: nil, type_of: "email_reply")
        get "/canned_responses?type_of=email_reply", headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq 2
      end
    end
  end
end
