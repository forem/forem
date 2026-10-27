require "rails_helper"

RSpec.describe "ResponseTemplate" do
  let(:user) { create(:user) }
  let(:trusted_user) { create(:user, :trusted) }
  let(:moderator) { create(:user, :tag_moderator) }
  let(:admin) { create(:user, :admin) }

  describe "GET /response_templates #index" do
    it "has status unauthorized if no user is logged in" do
      get response_templates_path, headers: { HTTP_ACCEPT: "application/json" }
      expect(response.status_message).to eq "Unauthorized"
    end

    context "when signed in as a regular user" do
      before { sign_in user }

      it "raises RoutingError if the format is not JSON" do
        expect { get response_templates_path }.to raise_error ActionController::RoutingError
      end

      it "responds with a JSON array of only the user's personal response templates", :aggregate_failures do
        create(:response_template, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: user, type_of: "personal_comment")

        headers = { HTTP_ACCEPT: "application/json" }
        get response_templates_path, params: { type_of: "personal_comment" }, headers: headers

        expect(response.media_type).to eq "application/json"
        expect(response.parsed_body.class).to eq Array
        expect(response.parsed_body.length).to eq 2
        expect(response.parsed_body.pluck("user_id")).to eq([user.id, user.id])
      end

      it "returns a hash with personal response templates if type_of unspecified", :aggregate_failures do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: user, type_of: "personal_comment")
        get response_templates_path, params: { type_of: nil }, headers: { HTTP_ACCEPT: "application/json" }
        json = response.parsed_body
        expect(response.media_type).to eq "application/json"
        expect(json.keys).to contain_exactly("personal_comment")
        expect(json.values.flatten.count).to eq(2)
      end

      it "raises an error if trying to view moderator or admin response templates", :aggregate_failures do
        expect do
          get response_templates_path, params: { type_of: "mod_comment" }, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError

        expect do
          get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as a mod user" do
      before { sign_in moderator }

      it "responds with JSON and returns the correct amount of moderator response templates", :aggregate_failures do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: moderator, type_of: "personal_comment")
        get response_templates_path, params: { type_of: "mod_comment" }, headers: { HTTP_ACCEPT: "application/json" }
        expect(response.media_type).to eq "application/json"
        expect(response.parsed_body.length).to eq 2
      end

      it "returns both personal and moderator response templates if type_of unspecified" do
        create_list(:response_template, 2, user: nil, type_of: "mod_comment")
        create_list(:response_template, 2, user: moderator, type_of: "personal_comment")
        get response_templates_path, params: { type_of: nil }, headers: { HTTP_ACCEPT: "application/json" }
        json = response.parsed_body
        expect(json.keys).to contain_exactly("mod_comment", "personal_comment")
        expect(json.values.flatten.count).to eq(4)
      end

      it "raises unauthorized error if trying to view admin response templates" do
        expect do
          get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        end.to raise_error Pundit::NotAuthorizedError
      end
    end

    context "when signed in as an admin" do
      before { sign_in admin }

      it "allows access with status OK and returns an array of admin level response templates", :aggregate_failures do
        create_list(:response_template, 2, user: nil, type_of: "email_reply", content_type: "html")
        get response_templates_path, params: { type_of: "email_reply" }, headers: { HTTP_ACCEPT: "application/json" }
        expect(response.status_message).to eq "OK"
        expect(response.parsed_body.length).to eq 2
      end
    end
  end

  describe "POST /response_templates #create" do
    context "when signed in as normal user" do
      before { sign_in user }

      let(:attributes) do
        {
          title: "some_title",
          content: "some content",
          type_of: "personal_comment"
        }
      end

      it "successfully creates the proper response template and redirects to the edit page", :aggregate_failures do
        post response_templates_path, params: {
          response_template: {
            title: attributes[:title],
            content: attributes[:content]
          }
        }

        response_template = ResponseTemplate.last
        expect(response_template.user_id).to eq user.id
        expect(response_template.title).to eq attributes[:title]
        expect(response_template.content).to eq attributes[:content]
        expect(response_template.type_of).to eq attributes[:type_of]
        expect(response.redirect_url).to include user_settings_path(tab: "response-templates",
                                                                    id: response_template.id)
      end

      it "can only create personal response templates" do
        post response_templates_path, params: {
          response_template: {
            title: attributes[:title],
            content: attributes[:content],
            type_of: "mod_comment"
          }
        }

        response_template = ResponseTemplate.last
        expect(response_template.type_of).to eq "personal_comment"
      end
    end

    context "when signed in as trusted user" do
      before { sign_in trusted_user }

      let(:attributes) do
        {
          title: "some_title",
          content: "some content",
          type_of: "mod_comment"
        }
      end

      it "successfully creates a personal response template and redirects to the edit page", :aggregate_failures do
        post response_templates_path, params: {
          response_template: {
            title: attributes[:title],
            content: attributes[:content]
          }
        }

        response_template = ResponseTemplate.last
        expect(response_template.user_id).to eq trusted_user.id
        expect(response_template.title).to eq attributes[:title]
        expect(response_template.content).to eq attributes[:content]
        expect(response_template.type_of).to eq "personal_comment"
        expect(response.redirect_url).to include user_settings_path(tab: "response-templates",
                                                                    id: response_template.id)
      end

      it "**cannot** create a mod_comment response template" do
        post response_templates_path, params: {
          response_template: {
            title: attributes[:title],
            content: attributes[:content],
            type_of: attributes[:type_of]
          }
        }

        expect(ResponseTemplate.count).to be_zero
        expect(response).to have_http_status(:redirect)

        expect(response.redirect_url).to include user_settings_path(tab: "response-templates",
                                                                    id: nil)
      end
    end
  end

  describe "PATCH /response_templates/:id #update" do
    context "when signed-in as normal user updating a personal template" do
      before { sign_in user }

      let(:response_template) { create(:response_template, user: user) }

      it "successfully updates the response template and redirects back to it", :aggregate_failures do
        title = "something else"
        patch response_template_path(response_template.id), params: { response_template: { title: title } }
        expect(ResponseTemplate.first.title).to eq title
        expect(response.redirect_url).to include user_settings_path(tab: "response-templates",
                                                                    id: ResponseTemplate.first.id)
      end

      it "shows the previously written content on a failed submission" do
        content = "something something something"
        patch response_template_path(response_template.id),
              params: { response_template: { title: "", content: content } }
        follow_redirect!
        expect(response.body).to include content
      end
    end

    context "when signed-in as trusted user updating a mod_comment template" do
      before { sign_in trusted_user }

      let(:response_template) { create(:response_template, user: nil, type_of: "mod_comment") }

      it "does not permit the action" do
        title = "something else"
        expect do
          patch response_template_path(response_template.id), params: { response_template: { title: title } }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when signed-in as super_moderator user updating a mod_comment template" do
      before { sign_in create(:user, :super_moderator) }

      let(:response_template) { create(:response_template, user: nil, type_of: "mod_comment") }

      it "successfully updates the response template" do
        title = "something else"
        patch response_template_path(response_template.id), params: { response_template: { title: title } }
        expect(ResponseTemplate.first.title).to eq title
      end

      it "does not permit changing template type_of" do
        patch response_template_path(response_template.id),
              params: { response_template: { type_of: "personal_comment" } }
        expect(ResponseTemplate.first.type_of).to eq("mod_comment")
      end
    end
  end

  describe "DELETE /response_templates/:id #destroy" do
    before do
      sign_in user
      delete response_template_path(response_template.id)
    end

    let(:response_template) { create(:response_template, user: user) }

    it "successfully destroys the response template and redirects to /settings/response_templates",
       :aggregate_failures do
      expect(ResponseTemplate.count).to eq 0
      expect(response.redirect_url).to include user_settings_path(tab: "response-templates")
    end
  end
end
