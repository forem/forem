require "rails_helper"

RSpec.describe Api::Admin::ApiError do
  it "exposes error_code, status, and message" do
    err = described_class.new(:user_not_found, "User 42 not found", status: 404)

    expect(err.error_code).to eq(:user_not_found)
    expect(err.status).to eq(404)
    expect(err.message).to eq("User 42 not found")
  end

  it "defaults status to 400 when omitted" do
    err = described_class.new(:bad_request, "Bad request")

    expect(err.status).to eq(400)
  end

  it "is a StandardError subclass so rescue_from picks it up" do
    expect(described_class.ancestors).to include(StandardError)
  end
end
