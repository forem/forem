FactoryBot.define do
  factory :agent_session do
    user
    title { "Test Session" }
    tool_name { "claude_code" }
    normalized_data do
      {
        "messages" => [
          { "index" => 0, "role" => "user", "content" => [{ "type" => "text", "text" => "Hello" }] },
          { "index" => 1, "role" => "assistant", "content" => [{ "type" => "text", "text" => "Hi there" }] },
        ],
        "metadata" => { "tool_name" => "claude_code", "total_messages" => 2 }
      }
    end
  end
end
