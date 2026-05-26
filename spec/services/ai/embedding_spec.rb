require "rails_helper"

RSpec.describe Ai::Embedding do
  describe "#call" do
    let(:api_key) { "fake_key" }
    let(:text) { "hello world" }
    let(:service) { described_class.new(api_key: api_key) }

    it "calls the Gemini embedContent API and returns embedding values" do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key=fake_key")
        .with(
          body: hash_including(
            model: "models/gemini-embedding-2",
            content: { parts: [{ text: text }] },
            outputDimensionality: 768,
            taskType: "RETRIEVAL_DOCUMENT"
          )
        )
        .to_return(
          status: 200,
          body: { embedding: { values: [0.1, 0.2, 0.3] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect(service.call(text)).to eq([0.1, 0.2, 0.3])
    end

    it "raises an error on failure" do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-2:embedContent?key=fake_key")
        .to_return(status: 400, body: { error: { message: "Bad Request" } }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect { service.call(text) }.to raise_error(/API Error: 400 - Bad Request/)
    end
  end
end
