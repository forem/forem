require "rails_helper"

RSpec.describe "ResponseTemplate", type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :tag_moderator) }
  let(:admin) { create(:user, :admin) }

  describe "GET /response_templates #index" do
    it "returns not found if no user is logged in" do
      expect do
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
      end.to raise_error ActiveRecord::RecordNotFound
    end

    context "when signed in as a regular user" do
      before { sign_in user }

      it "responds with JSON" do
        create(:response_template, user: user, type_of: "personal_comment")
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
        expect(response.content_type).to eq "application/json"
      end

      it "returns an array of all the user's response templates" do
        total_response_templates = 2
        create(:response_template, user: nil, type_of: "mod_comment")
        create_list(:response_template, total_response_templates, user: user, type_of: "personal_comment")
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq total_response_templates
      end

      it "returns only the users' response templates" do
        create(:response_template, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: user, type_of: "personal_comment")
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["user_id"] }
        expect(user_ids).to eq [user.id, user.id]
      end

      it "raises an error if trying to view moderator response templates" do
        create(:response_template, user: nil, type_of: "mod_comment")
        params = {
          type_of: "mod_comment",
          personal_included: "true"
        }
        expect do
          get response_templates_path, params: params, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end

      it "raises an error if trying to view admin response templates" do
        create(:response_template, user: nil, type_of: "email_reply", content_type: "html")
        expect do
          get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as a mod user" do
      before { sign_in moderator }

      it "responds with JSON" do
        create(:response_template, user: moderator, type_of: "personal_comment")
        get response_templates_path, params: { type_of: "mod_comment", personal_included: "true" }, headers: { HTTP_ACCEPT: "application/json" }
        expect(response.content_type).to eq "application/json"
      end

      it "returns an array of all relevant response templates" do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: moderator, type_of: "personal_comment")
        get response_templates_path, params: { type_of: "mod_comment", personal_included: "true" }, headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq 4
      end

      it "returns only the moderator and personal response templates with the correct params" do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: moderator, type_of: "personal_comment")

        get response_templates_path, params: { type_of: "mod_comment", personal_included: "true" }, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["user_id"] }
        expect(user_ids).to eq [nil, nil, moderator.id, moderator.id]
      end

      it "returns the user's response templates when no params are given" do
        create_list(:response_template, 2, user: moderator, type_of: "personal_comment")
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["user_id"] }
        expect(user_ids).to eq [moderator.id, moderator.id]
      end

      it "raises unauthorized error if trying to view admin response templates" do
        create_list(:response_template, 2, user: nil, type_of: "email_reply", content_type: "html")
        expect do
          get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as an admin" do
      before { sign_in admin }

      it "returns only the moderator and personal response templates with the correct params" do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: admin, type_of: "personal_comment")

        get response_templates_path, params: { type_of: "mod_comment", personal_included: "true" }, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["user_id"] }
        expect(user_ids).to eq [nil, nil, admin.id, admin.id]
      end

      it "returns the user's response templates" do
        create_list(:response_template, 2, user: admin, type_of: "personal_comment")
        get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
        user_ids = JSON.parse(response.body).map { |hash| hash["user_id"] }
        expect(user_ids).to eq [admin.id, admin.id]
      end

      it "allows access and returns an array of admin level response templates" do
        create_list(:response_template, 2, user: nil, type_of: "email_reply", content_type: "html")
        get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        expect(JSON.parse(response.body).length).to eq 2
      end
    end
  end
end
