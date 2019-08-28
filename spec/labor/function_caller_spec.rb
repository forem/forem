require "rails_helper"

RSpec.describe FunctionCaller do
  let(:payload) { { user_id: 1, name: "hello" } }
  let(:dummy_client) { double }
  let(:result) { OpenStruct.new(payload: [{ body: { message: "hi" }.to_json }.to_json]) }

  before do
    allow(dummy_client).to receive(:invoke).and_return(result)
  end

  it "calls the aws_lambda_client" do
    described_class.call("some_function", payload, dummy_client)
    expect(dummy_client).to have_received(:invoke).with(function_name: "some_function", payload: payload)
  end

  it "returns parsed value" do
    value = described_class.call("some_function", payload, dummy_client)
    expect(value).to eq("hi")
  end
end
