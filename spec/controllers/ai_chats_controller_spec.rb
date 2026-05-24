require "rails_helper"

RSpec.describe AiChatsController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET #index" do
    context "when AI_AVAILABLE is true" do
      before do
        stub_const("AI_AVAILABLE", true)
      end

      it "returns a success response" do
        get :index
        expect(response).to be_successful
      end
    end

    context "when AI_AVAILABLE is false" do
      before do
        stub_const("AI_AVAILABLE", false)
      end

      it "redirects to root path" do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context "when user is not logged in" do
      before do
        sign_out user
      end

      it "redirects to sign in" do
        get :index
        expect(response).to have_http_status(:found) # Redirect to auth
      end
    end
  end

  describe "POST #create" do
    let(:chat_service) { instance_double(Ai::ChatService) }

    before do
      allow(Ai::ChatService).to receive(:new).and_return(chat_service)
    end

    context "when AI_AVAILABLE is true" do
      before do
        stub_const("AI_AVAILABLE", true)
      end

      it "returns success with AI message" do
        allow(chat_service).to receive(:generate_response).and_return({
                                                                        response: "AI Reply",
                                                                        history: [{ role: "user", text: "hi" },
                                                                                  { role: "assistant",
                                                                                    text: "AI Reply" }]
                                                                      })

        post :create, params: { message: "hi" }, format: :json

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("<p>AI Reply</p>\n")
        expect(json["history"]).to be_an(Array)
      end

      it "returns error if message is blank" do
        post :create, params: { message: "" }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when AI_AVAILABLE is false" do
      before do
        stub_const("AI_AVAILABLE", false)
      end

      it "returns forbidden for JSON requests" do
        post :create, params: { message: "hi" }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
