require "rails_helper"

RSpec.describe Ai::GeminiDecision::Client do
  let(:client) { described_class.new(api_key: "gemini-key", model: "gemini-decision-1") }
  let(:endpoint) { "https://generativelanguage.googleapis.com/v1beta/decisions" }
  let(:questions) do
    {
      is_urgent: Ai::TypeSafe::Questions.noul(
        { question: "Does `message` convey urgency?", focus: "Look for financial impact." },
        yes: "Time-sensitive issue",
        no: { includes: "Routine product inquiry" },
      ),
      severity: Ai::TypeSafe::Questions.score(
        "How severe is `message`?",
        ["Cosmetic", { what: "Degraded", examples: ["slow"] }, "Blocking"],
      ),
      team: Ai::TypeSafe::Questions.choice(
        "Which team handles `message`?",
        { billing: { scope: "Payments" }, technical: nil },
      )
    }
  end
  let(:state) { { message: "Payouts have failed for 3 days." } }
  let(:success_body) do
    {
      answers: {
        is_urgent: { type: "noul", noul: 0.95, confidence: 0.95 },
        severity: {
          type: "score",
          score: 1.5,
          legend: { "0" => "Cosmetic", "1" => '{"what":"Degraded","examples":["slow"]}', "2" => "Blocking" },
          probabilities: { "0" => 0.0, "1" => 0.5, "2" => 0.5 },
          confidence: 0.5
        },
        team: {
          type: "choice",
          choice: "billing",
          probabilities: { billing: 0.88, technical: 0.12 },
          confidence: 0.88
        }
      },
      usage: {
        total_input_tokens: 300,
        input_tokens_by_modality: [{ modality: "text", tokens: 300 }],
        total_output_tokens: 0,
        total_tokens: 300
      }
    }.to_json
  end

  def stub_success(body = success_body)
    stub_request(:post, endpoint).to_return(status: 200, body: body,
                                            headers: { "Content-Type" => "application/json" })
  end

  it "posts serialized structured input and Gemini Decisions-formatted questions with x-goog-api-key",
     :aggregate_failures do
    stub_success

    client.evaluate(state: state, questions: questions)

    expect(
      a_request(:post, endpoint).with do |request|
        body = JSON.parse(request.body)
        request.headers["X-Goog-Api-Key"] == "gemini-key" &&
          body["model"] == "gemini-decision-1" &&
          body["input"] == state.to_json &&
          body["questions"]["is_urgent"] == {
            "type" => "noul",
            "instructions" => {
              question: "Does `message` convey urgency?",
              focus: "Look for financial impact."
            }.to_json,
            "criteria" => {
              "true_description" => "Time-sensitive issue",
              "false_description" => { includes: "Routine product inquiry" }.to_json
            }
          } &&
          body["questions"]["team"]["criteria"] == {
            "billing" => { scope: "Payments" }.to_json,
            "technical" => ""
          } &&
          body["questions"]["severity"]["criteria"] == [
            "Cosmetic",
            { what: "Degraded", examples: ["slow"] }.to_json,
            "Blocking",
          ]
      end,
    ).to have_been_made.once
  end

  it "passes multimodal content block arrays directly without double-serializing" do
    multimodal_input = [
      { type: "text", text: "Customer return photo." },
      { type: "image", data: "base64bytes", mime_type: "image/jpeg", resolution: "low" },
    ]
    stub_request(:post, endpoint).to_return(
      status: 200,
      body: { answers: { damaged: { type: "noul", noul: 0.91, confidence: 0.91 } }, usage: {} }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    result = client.evaluate(
      state: multimodal_input,
      questions: { damaged: Ai::TypeSafe::Questions.noul("Is the item damaged?") },
    )

    expect(result.noul(:damaged)).to eq(0.91)
    expect(
      a_request(:post, endpoint).with do |request|
        JSON.parse(request.body)["input"] == multimodal_input.map(&:stringify_keys)
      end,
    ).to have_been_made.once
  end

  it "normalizes question keys outside [A-Za-z0-9_-]{1,64} on the wire and restores original keys on Result",
     :aggregate_failures do
    long_key = "long_#{'x' * 80}"
    tricky_questions = {
      "tag::javascript" => Ai::TypeSafe::Questions.noul("Is it JavaScript?"),
      "tag::c++" => Ai::TypeSafe::Questions.noul("Is it C++?"),
      "tag::c#" => Ai::TypeSafe::Questions.noul("Is it C#?"),
      "candidate::1049" => Ai::TypeSafe::Questions.noul("Does candidate 1049 match?"),
      long_key => Ai::TypeSafe::Questions.noul("Long key?")
    }

    stub_request(:post, endpoint).to_return do |request|
      sent_keys = JSON.parse(request.body).fetch("questions").keys
      expect(sent_keys.size).to eq(5)
      expect(sent_keys).to all(match(/\A[A-Za-z0-9_-]{1,64}\z/))

      answers = sent_keys.index_with.with_index do |_key, index|
        { "type" => "noul", "noul" => (0.1 * (index + 1)).round(2), "confidence" => 0.9 }
      end
      {
        status: 200,
        body: { answers: answers, usage: { total_input_tokens: 50, total_output_tokens: 0, total_tokens: 50 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      }
    end

    result = client.evaluate(state: "Code sample", questions: tricky_questions)

    expect(result.nouls_with_prefix("tag::")).to eq("javascript" => 0.1, "c++" => 0.2, "c#" => 0.3)
    expect(result.noul("candidate::1049")).to eq(0.4)
    expect(result.noul(long_key)).to eq(0.5)
  end

  it "returns typed answers with the configured model name" do
    stub_success

    result = client.evaluate(state: state, questions: questions)

    expect(result.model).to eq("gemini-decision-1")
    expect(result.noul(:is_urgent)).to eq(0.95)
    expect(result.choice(:team)).to have_attributes(choice: "billing", confidence: 0.88)
    expect(result.score(:severity)).to have_attributes(score: 1.5, levels: 3, normalized: 0.75)
  end

  it "records an AiAudit with zero output tokens and input token usage" do
    stub_success
    wrapper = Ai::ArticleCheck.allocate

    expect do
      described_class.new(api_key: "gemini-key", wrapper: wrapper).evaluate(state: state, questions: questions)
    end.to change(AiAudit, :count).by(1)

    audit = AiAudit.last
    expect(audit).to have_attributes(
      ai_model: "gemini-decision-1",
      wrapper_object_class: "Ai::ArticleCheck",
      wrapper_object_version: Ai::ArticleCheck::VERSION,
      prompt_token_count: 300,
      candidates_token_count: 0,
      total_token_count: 300,
      status_code: 200,
      error_message: nil,
    )
  end

  it "raises Ai::Base::ProhibitedContentError without retrying or tripping the circuit breaker on prohibited_content" do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    stub_request(:post, endpoint).to_return(
      status: 400,
      body: { error: { code: "prohibited_content", message: "Blocked for prohibited content." } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    expect do
      client.evaluate(state: state, questions: questions)
    end.to raise_error(Ai::Base::ProhibitedContentError, /prohibited_content/)

    expect(a_request(:post, endpoint)).to have_been_made.once
    expect(described_class).not_to be_circuit_open
    expect(AiAudit.last.error_message).to include("prohibited_content")
  end

  it "raises Error without retrying on safety or validation 400 responses" do
    stub_request(:post, endpoint).to_return(
      status: 400,
      body: { error: { code: "safety", message: "Request blocked due to safety violations." } }.to_json,
      headers: { "Content-Type" => "application/json" },
    )

    expect { client.evaluate(state: state, questions: questions) }
      .to raise_error(described_class::Error, /400 - Request blocked due to safety violations/)
    expect(a_request(:post, endpoint)).to have_been_made.once
  end

  it "retries rate-limited and overloaded responses, then succeeds" do
    stub_request(:post, endpoint)
      .to_return(
        { status: 429, body: { error: { message: "Resource exhausted" } }.to_json,
          headers: { "Content-Type" => "application/json" } },
        { status: 503, body: "{}", headers: { "Content-Type" => "application/json" } },
      )
      .then.to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

    expect(client.evaluate(state: state, questions: questions).noul(:is_urgent)).to eq(0.95)
    expect(a_request(:post, endpoint)).to have_been_made.times(3)
    expect(AiAudit.last(3).map(&:retry_count)).to eq([0, 1, 2])
  end

  it "does not retry when asked to fail fast" do
    stub_request(:post, endpoint).to_return(status: 503, body: "{}", headers: { "Content-Type" => "application/json" })
    fast_client = described_class.new(api_key: "gemini-key", **described_class::FAIL_FAST)

    expect { fast_client.evaluate(state: state, questions: questions) }.to raise_error(described_class::Error, /503/)
    expect(a_request(:post, endpoint)).to have_been_made.once
  end

  context "with the circuit breaker" do
    let(:fast_client) { described_class.new(api_key: "gemini-key", **described_class::FAIL_FAST) }

    before { allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new) }

    def fail_outage_calls(count)
      count.times do
        fast_client.evaluate(state: state, questions: questions)
      rescue described_class::Error, *described_class::NETWORK_ERRORS
        nil
      end
    end

    it "opens after repeated outage failures without affecting TypeSafe's circuit breaker" do
      stub_request(:post, endpoint)
        .to_return(status: 503, body: "{}", headers: { "Content-Type" => "application/json" })
      fail_outage_calls(described_class::CIRCUIT_FAILURE_THRESHOLD)

      expect(described_class).to be_circuit_open
      expect(Ai::TypeSafe::Client).not_to be_circuit_open
      expect { fast_client.evaluate(state: state, questions: questions) }
        .to raise_error(described_class::CircuitOpenError)
    end
  end

  it "rejects a response without answers" do
    stub_request(:post, endpoint).to_return(status: 200, body: { usage: {} }.to_json,
                                            headers: { "Content-Type" => "application/json" })

    expect { client.evaluate(state: state, questions: questions) }.to raise_error(described_class::Error, /Malformed/)
  end

  it "requires at least one question" do
    expect { client.evaluate(state: state, questions: {}) }.to raise_error(ArgumentError)
  end
end
