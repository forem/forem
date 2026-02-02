require "rails_helper"

RSpec.describe Ai::Base do
  let(:api_key) { "test_key" }
  let(:model) { "gemini-test" }
  let(:client) { described_class.new(api_key: api_key, model: model) }

  describe "#embed" do
    let(:text) { "Hello world" }
    let(:embedding) { [0.1, 0.2, 0.3] }
    let(:api_response) do
      {
        "embedding" => {
          "values" => embedding
        }
      }
    end

    before do
      stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}")
        .with(
          body: {
            model: "models/text-embedding-004",
            content: {
              parts: [{ text: text }]
            }
          }.to_json
        )
        .to_return(status: 200, body: api_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it "calls the embedding API and returns values" do
      result = client.embed(text)
      expect(result).to eq(embedding)
    end

    context "when API fails" do
      before do
        stub_request(:post, "https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=#{api_key}")
          .to_return(status: 500, body: { error: { message: "Internal Server Error" } }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it "raises an error" do
        expect { client.embed(text) }.to raise_error(/API Error: 500/)
      end
    end
  end
end
