require "rails_helper"

RSpec.describe Ai::Base do
  describe "#call" do
    let(:api_key) { "test_api_key" }
    let(:model) { "gemini-1.5-pro" }
    let(:client) { described_class.new(api_key: api_key, model: model) }
    let(:prompt) { "Hello world" }
    let(:mock_response) do
      instance_double(HTTParty::Response, success?: true,
                                          parsed_response: { "candidates" => [{ "content" => { "parts" => [{ "text" => "Hello there" }] } }], "usageMetadata" => { "promptTokenCount" => 3, "candidatesTokenCount" => 2, "totalTokenCount" => 5 } }, code: 200, body: '{"candidates":[{"content":{"parts":[{"text":"Hello there"}]}}]}')
    end

    before do
      allow(described_class).to receive(:post).and_return(mock_response)
    end

    it "makes a POST request to the Gemini API" do
      client.call(prompt)
      expect(described_class).to have_received(:post).with(
        "/models/#{model}:generateContent?key=#{api_key}",
        hash_including(body: { contents: [{ parts: [{ text: prompt }] }] }.to_json),
      )
    end

    it "logs an AiAudit record exactly once" do
      expect { client.call(prompt) }.to change { AiAudit.count }.by(1)

      audit = AiAudit.last
      expect(audit.ai_model).to eq(model)
      expect(audit.wrapper_object_class).to be_nil
      expect(audit.response_body).to eq(mock_response.parsed_response)
      expect(audit.status_code).to eq(200)
      expect(audit.latency_ms).to be_a(Integer)
      expect(audit.prompt_token_count).to eq(3)
      expect(audit.candidates_token_count).to eq(2)
      expect(audit.total_token_count).to eq(5)
      expect(audit.error_message).to be_nil
    end

    context "with wrapper and affected user/content" do
      let(:user) { create(:user) }
      let(:wrapper) { DummyAiWrapper.new }
      let(:client_with_context) do
        described_class.new(api_key: api_key, model: model, wrapper: wrapper, affected_user: user,
                            affected_content: article)
      end
      let(:article) { create(:article, user: user) }

      before do
        stub_const("DummyAiWrapper", Class.new do
          VERSION = "1.0"
        end)
      end

      it "logs AiAudit with provided context" do
        expect { client_with_context.call(prompt) }.to change { AiAudit.count }.by(1)

        audit = AiAudit.last
        expect(audit.wrapper_object_class).to eq("DummyAiWrapper")
        expect(audit.wrapper_object_version).to eq("1.0")
        expect(audit.affected_user).to eq(user)
        expect(audit.affected_content).to eq(article)
      end
    end

    context "when the API returns an error" do
      let(:error_response) do
        instance_double(HTTParty::Response, success?: false,
                                            parsed_response: { "error" => { "message" => "Rate Limit Exceeded" } }, code: 429)
      end

      before do
        allow(described_class).to receive(:post).and_return(error_response)
      end

      it "logs the audit with error details and raises exception" do
        expect { client.call(prompt) }.to raise_error(RuntimeError, "API Error: 429 - Rate Limit Exceeded")
          .and change { AiAudit.count }.by(1)

        audit = AiAudit.last
        expect(audit.status_code).to eq(429)
        expect(audit.error_message).to eq("API Error: 429 - Rate Limit Exceeded")
        expect(audit.latency_ms).to be_a(Integer)
        expect(audit.response_body).to eq(error_response.parsed_response)
      end
    end
  end
end
