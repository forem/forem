require "rails_helper"

RSpec.describe "ResponseTemplate", type: :request do
  let(:user) { create(:user) }
  let(:moderator) { create(:user, :tag_moderator) }
  let(:admin) { create(:user, :admin) }

  describe "POST /response_templates #create" do
    before { sign_in user }

    let(:attributes) do
      {
        title: "some_title",
        content: "some content",
        type_of: "personal_comment"
      }
    end

    it "successfully creates the proper response template" do
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
    end

    it "redirects to the edit page upon success" do
      post response_templates_path, params: {
        response_template: {
          title: attributes[:title],
          content: attributes[:content]
        }
      }
      expect(response.redirect_url).to include user_settings_path(tab: "response-templates", id: ResponseTemplate.last.id)
    end
  end

  describe "PATCH /response_templates/:id #update" do
    before { sign_in user }

    let(:response_template) { create(:response_template, user: user) }

    it "successfully updates the response template" do
      title = "something else"
      patch response_template_path(response_template.id), params: { response_template: { title: title } }
      expect(ResponseTemplate.first.title).to eq title
    end

    it "redirects back to the response template" do
      patch response_template_path(response_template.id), params: { response_template: { title: "something else" } }
      expect(response.redirect_url).to include user_settings_path(tab: "response-templates", id: ResponseTemplate.first.id)
    end

    it "shows the previously written content on a failed submission" do
      content = "something something something"
      patch response_template_path(response_template.id), params: { response_template: { title: "", content: content } }
      follow_redirect!
      expect(response.body).to include content
    end
  end

  describe "DELETE /response_templates/:id #destroy" do
    before do
      sign_in user
      delete response_template_path(response_template.id)
    end

    let(:response_template) { create(:response_template, user: user) }

    it "successfully destroys the response template" do
      expect(ResponseTemplate.count).to eq 0
    end

    it "redirects to /settings/response_templates" do
      expect(response.redirect_url).to include user_settings_path(tab: "response-templates")
    end
  end
end
