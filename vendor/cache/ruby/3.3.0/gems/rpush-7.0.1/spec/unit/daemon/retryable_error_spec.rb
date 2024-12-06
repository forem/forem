require "unit_spec_helper"

describe Rpush::RetryableError do
  let(:response) { double(code: 401, header: { 'retry-after' => 3600 }) }
  let(:error) { Rpush::RetryableError.new(401, 12, "Unauthorized", response) }

  it "returns an informative message" do
    expect(error.to_s).to eq "Retryable error for 12, received error 401 (Unauthorized) - retry after 3600"
  end

  it "returns the error code" do
    expect(error.code).to eq 401
  end
end
