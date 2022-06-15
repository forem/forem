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

  context "when request is v0 and does not include an api key" do
    let(:headers) { { Accept: "application/v0+json", "api-key": nil } }

    it "responds with a Warning header with code 299" do
      call_based_on_method(method, path, headers)

      expect(response).to have_http_status(:success)
      expect(response.headers["Warning"])
        .to eq("299 - This endpoint will require the `api-key` header to be set in future.")
    end
  end

  # context "when request is v1 and includes an api key" do
  #   let(:headers) { { Accept: "application/vnd.forem.api-v1+json", "api-key": "abc123" } }

  #   it "does not have a Warning header" do
  #     call_based_on_method(method, path, headers)

  #     expect(response).to have_http_status(:success)
  #     expect(response.headers["Warning"]).to be_nil
  #   end
  # end
end
