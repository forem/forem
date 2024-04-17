require "rails_helper"

# from https://github.com/algolia/algoliasearch-client-ruby/blob/master/test/algolia/integration/mocks/mock_requester.rb
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
      headers: {},
    )
  end

  def get_connection(host)
    @connection = host
  end

  def build_url(host)
    host.protocol + host.url
  end
end
# rubocop:disable RSpec/AnyInstance
RSpec.describe AlgoliaSearch::SearchIndexWorker, type: :worker do
  let(:user) { create(:user) }

  before do
    mock_requester = MockRequester.new
    algolia_config = Algolia::Search::Config.new(AlgoliaSearch.configuration)
    mock_client = Algolia::Search::Client.new(algolia_config, http_requester: mock_requester)

    AlgoliaSearch.instance_variable_set(:@client, mock_client)
  end

  it "remove the record from Algolia if record is deleted" do
    expect_any_instance_of(Algolia::Search::Index).to receive(:delete_object).with(user.id)

    described_class.new.perform(user.class.name, user.id, true)
  end

  it "index the record in Algolia if record is created" do
    allow(User).to receive(:find).with(user.id).and_return(user)
    allow(user).to receive(:index!)
    described_class.new.perform(user.class.name, user.id, false)
    expect(user).to have_received(:index!)
  end
end
# rubocop:enable RSpec/AnyInstance
