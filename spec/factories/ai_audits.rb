FactoryBot.define do
  factory :ai_audit do
    ai_model { "gemini-1.5-pro" }
    wrapper_object_class { "Ai::Base" }
    association :affected_user, factory: :user
    request_body { { prompt: "Test prompt" } }
    response_body { { text: "Test response" } }
    latency_ms { 500 }
    status_code { 200 }
    prompt_token_count { 10 }
    candidates_token_count { 20 }
    total_token_count { 30 }
    retry_count { 0 }
  end
end
