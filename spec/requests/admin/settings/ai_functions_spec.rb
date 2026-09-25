require "rails_helper"

RSpec.describe "/admin/settings/ai_functions" do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    stub_const("Ai::Base::DEFAULT_KEY", "gemini-key")
    stub_const("Ai::TypeSafe::Client::DEFAULT_KEY", "typesafe-key")
  end

  describe "POST /admin/settings/ai_functions" do
    it "saves per-function model selections globally" do
      sign_in super_admin

      post admin_settings_ai_functions_path, params: {
        settings_ai_functions: {
          function_models: {
            article_spam_check: "jev",
            comment_spam_check: "default",
            article_summary: "gemini_lite"
          }
        }
      }

      expect(response).to have_http_status(:ok)
      expect(Settings::AiFunctions.global_function_models)
        .to eq("article_spam_check" => "jev", "article_summary" => "gemini_lite")
      expect(Ai::FunctionConfig.jev?(:article_spam_check)).to be(true)
    end

    it "drops options a function does not support" do
      sign_in super_admin

      post admin_settings_ai_functions_path, params: {
        settings_ai_functions: { function_models: { article_summary: "jev", article_spam_check: "bogus" } }
      }

      expect(response).to have_http_status(:ok)
      expect(Settings::AiFunctions.global_function_models).to eq({})
    end

    it "is only available to super admins" do
      sign_in create(:user, :admin)

      expect do
        post admin_settings_ai_functions_path, params: {
          settings_ai_functions: { function_models: { article_spam_check: "jev" } }
        }
      end.to raise_error(Pundit::NotAuthorizedError)
      expect(Settings::AiFunctions.global_function_models).to eq({})
    end
  end

  describe "GET /admin/customization/config" do
    it "renders a model picker for each configurable function" do
      Settings::AiFunctions.set_global_function_models("content_moderation" => "jev")
      sign_in super_admin

      get admin_config_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AI Models")
      expect(response.body).to include("settings_ai_functions[function_models][content_moderation]")
      expect(response.body).to include("TypeSafe Jev: #{Ai::TypeSafe::Client::DEFAULT_MODEL}")
      expect(response.body).not_to include("settings_ai_functions[function_models][embeddings]")
    end
  end
end
