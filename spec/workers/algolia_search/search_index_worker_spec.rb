require "rails_helper"

class MockRequester
  attr_accessor :requests

  def initialize
    @connection = nil
    @requests   = []
  end

  def send_request(host, method, path, body, headers, timeout, connect_timeout)
    request = {
      host: host,
      method: method,
      path: path,
      body: body,
      headers: headers,
      timeout: timeout,
      connect_timeout: connect_timeout
    }

    @requests.push(request)

    Algolia::Http::Response.new(
      status: 200,
      body: '{"hits": [], "status": "published"}',
      headers: {}
    )
  end

  def get_connection(host)
    @connection = host
  end

  def build_url(host)
    host.protocol + host.url
  end
end

RSpec.describe AlgoliaSearch::SearchIndexWorker, type: :worker do
  let(:user) { create(:user) }

  before(:all) do
    mock_requester = MockRequester.new
    mock_client = Algolia::Search::Client.new(
      Algolia::Search::Config.new(AlgoliaSearch.configuration),
      http_requester: mock_requester
    )

    AlgoliaSearch.instance_variable_set(:@client, mock_client)
  end

  it "remove the record from Algolia if record is deleted" do
    expect_any_instance_of(Algolia::Search::Index).to receive(:delete_object).with(user.id)

    described_class.new.perform(user.class.name, user.id, true)
  end

  it "index the record in Algolia if record is created" do
    expect(User).to receive(:find).with(user.id).and_return(user)
    expect_any_instance_of(User).to receive(:index!)

    described_class.new.perform(user.class.name, user.id, false)
  end
end
