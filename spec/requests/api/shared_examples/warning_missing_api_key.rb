RSpec.shared_examples "a legacy v0 API endpoint migrated to V1" do |method, path|
  # maybe a case here to swtich?
  def call_based_on_method(method, path, headers)
    case method
    when :get
      get path, headers: headers
    when :post
      post path, headers: headers
    when :put
      put path, headers: headers
    when :delete
      delete path, headers: headers
    end
  end

  before do
    allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(true)
  end

  context "when request is v0 and does not include an api key" do
    let(:headers) { { Accept: "application/v0+json", "api-key": nil } }

    it "responds with a Warning header with code 299" do
      call_based_on_method(method, path, headers)

      expect(response).to have_http_status(:success)
      # rubocop:disable Layout/LineLength
      expect(response.headers["Warning"])
        .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
      # rubocop:enable Layout/LineLength
    end
  end

  context "when request is v0 and does include an api key" do
    let(:headers) { { Accept: "application/v0+json", "api-key": "abc123" } }

    it "responds with a Warning header with code 299" do
      call_based_on_method(method, path, headers)

      expect(response).to have_http_status(:success)
      # rubocop:disable Layout/LineLength
      expect(response.headers["Warning"])
        .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
      # rubocop:enable Layout/LineLength
    end
  end
end
