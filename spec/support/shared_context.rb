RSpec.shared_context "when proper status" do
  before do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false
    Rails.application.env_config["action_dispatch.show_exceptions"] = true
  end

  after do
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = true
    Rails.application.env_config["action_dispatch.show_exceptions"] = false
  end
end

RSpec.configure do |rspec|
  rspec.include_context "when proper status", proper_status: true
end
