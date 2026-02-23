require "rails_helper"

RSpec.describe AiAudit, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:affected_user).class_name("User").optional }
    it { is_expected.to belong_to(:affected_content).optional }
  end

  describe "validations" do
    it "can be created with minimum attributes" do
      audit = AiAudit.new(
        ai_model: "gemini-1.5-pro",
        wrapper_object_class: "Ai::ChatService",
        wrapper_object_version: "1.0",
        request_body: { prompt: "hello" }.to_json,
        response_body: { text: "hi" }.to_json,
        retry_count: 0,
        prompt_token_count: 10,
        candidates_token_count: 20,
        total_token_count: 30,
        latency_ms: 125,
        status_code: 200,
        error_message: nil,
      )
      expect(audit).to be_valid
    end
  end
end
