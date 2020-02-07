require "rails_helper"

RSpec.describe FunctionCaller, type: :labor do
  let(:payload) { { user_id: 1, name: "hello" } }
  let(:dummy_client) { double }
  let(:result_struct) { Struct.new(:payload, keyword_init: true) }
  let(:result) { result_struct.new(payload: [{ body: { message: "hi" }.to_json }.to_json]) }

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

  it "doesn't fail when payload is empty" do
    empty_result = result_struct.new(payload: [nil])
    empty_client = double
    allow(empty_client).to receive(:invoke).and_return(empty_result)
    expect(described_class.call("some_function", payload, empty_client)).to be_nil
  end

  it "doesn't fail when payload is empty and is a hash" do
    empty_result = result_struct.new(payload: [{}.to_json])
    empty_client = double
    allow(empty_client).to receive(:invoke).and_return(empty_result)
    expect(described_class.call("some_function", payload, empty_client)).to be_nil
  end
end
