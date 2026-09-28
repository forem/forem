require "rails_helper"

RSpec.describe Ai::TypeSafe::Client do
  let(:client) { described_class.new(api_key: "ts-key", model: "jev-latest") }
  let(:endpoint) { "https://api.typesafe.ai/v1/systemone" }
  let(:questions) do
    {
      is_urgent: Ai::TypeSafe::Questions.noul("Does `message` convey urgency?"),
      severity: Ai::TypeSafe::Questions.score("How severe is `message`?", %w[Cosmetic Degraded Blocking]),
      team: Ai::TypeSafe::Questions.choice("Which team handles `message`?", { billing: "Payments", technical: nil })
    }
  end
  let(:state) { { message: "Payouts have failed for 3 days." } }
  let(:success_body) do
    {
      model: "jev-1.13.0",
      answers: {
        is_urgent: { type: "noul", noul: 0.95 },
        severity: { type: "score", score: 1.5, legend: { "0" => "Cosmetic", "1" => "Degraded", "2" => "Blocking" },
                    probabilities: { "0" => 0.0, "1" => 0.5, "2" => 0.5 }, confidence: 0.5 },
        team: { type: "choice", choice: "billing", probabilities: { billing: 0.88, technical: 0.12 }, confidence: 0.81 }
      },
      usage: { input_tokens: 300, output_tokens: 20 }
    }.to_json
  end

  def stub_success
    stub_request(:post, endpoint).to_return(status: 200, body: success_body,
                                            headers: { "Content-Type" => "application/json" })
  end

  it "posts the model, state and typed questions with bearer auth" do
    stub_success

    client.evaluate(state: state, questions: questions)

    expect(
      a_request(:post, endpoint).with do |request|
        body = JSON.parse(request.body)
        request.headers["Authorization"] == "Bearer ts-key" &&
          body["model"] == "jev-latest" &&
          body["state"] == { "message" => "Payouts have failed for 3 days." } &&
          body["questions"]["is_urgent"] == { "type" => "noul", "instructions" => "Does `message` convey urgency?" } &&
          body["questions"]["team"]["criteria"] == { "billing" => "Payments", "technical" => nil } &&
          body["questions"]["severity"]["criteria"] == %w[Cosmetic Degraded Blocking]
      end,
    ).to have_been_made.once
  end

  it "returns typed answers" do
    stub_success

    result = client.evaluate(state: state, questions: questions)

    expect(result.model).to eq("jev-1.13.0")
    expect(result.noul(:is_urgent)).to eq(0.95)
    expect(result.choice(:team)).to have_attributes(choice: "billing", confidence: 0.81)
    expect(result.score(:severity)).to have_attributes(score: 1.5, levels: 3, normalized: 0.75)
  end

  it "records an AiAudit with the versioned model and token usage" do
    stub_success
    wrapper = Ai::ArticleCheck.allocate

    expect do
      described_class.new(api_key: "ts-key", wrapper: wrapper).evaluate(state: state, questions: questions)
    end.to change(AiAudit, :count).by(1)

    audit = AiAudit.last
    expect(audit).to have_attributes(ai_model: "jev-1.13.0", wrapper_object_class: "Ai::ArticleCheck",
                                     prompt_token_count: 300, candidates_token_count: 20, total_token_count: 320,
                                     status_code: 200, error_message: nil)
    expect(audit.request_body["questions"].keys).to match_array(%w[is_urgent severity team])
  end

  it "retries rate-limited and overloaded responses, then succeeds" do
    stub_request(:post, endpoint)
      .to_return(
        { status: 429, body: { detail: "slow down" }.to_json, headers: { "Content-Type" => "application/json" } },
        { status: 529, body: "{}", headers: { "Content-Type" => "application/json" } },
      )
      .then.to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

    expect(client.evaluate(state: state, questions: questions).noul(:is_urgent)).to eq(0.95)
    expect(a_request(:post, endpoint)).to have_been_made.times(3)
    expect(AiAudit.last(3).map(&:retry_count)).to eq([0, 1, 2])
  end

  it "raises without retrying on a validation error" do
    stub_request(:post, endpoint).to_return(status: 422, body: { detail: "bad question" }.to_json,
                                            headers: { "Content-Type" => "application/json" })

    expect { client.evaluate(state: state, questions: questions) }
      .to raise_error(described_class::Error, /422 - bad question/)
    expect(a_request(:post, endpoint)).to have_been_made.once
    expect(AiAudit.last.error_message).to include("bad question")
  end

  it "gives up after the maximum number of retries" do
    stub_request(:post, endpoint).to_return(status: 529, body: "{}", headers: { "Content-Type" => "application/json" })

    expect { client.evaluate(state: state, questions: questions) }.to raise_error(described_class::Error, /529/)
    expect(a_request(:post, endpoint)).to have_been_made.times(described_class::MAX_RETRIES + 1)
  end

  it "rejects a response without answers" do
    stub_request(:post, endpoint).to_return(status: 200, body: { model: "jev-1.13.0" }.to_json,
                                            headers: { "Content-Type" => "application/json" })

    expect { client.evaluate(state: state, questions: questions) }.to raise_error(described_class::Error, /Malformed/)
  end

  it "requires at least one question" do
    expect { client.evaluate(state: state, questions: {}) }.to raise_error(ArgumentError)
  end
end
