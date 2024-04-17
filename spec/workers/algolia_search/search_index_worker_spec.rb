require "rails_helper"
# rubocop:disable RSpec/AnyInstance
RSpec.describe AlgoliaSearch::SearchIndexWorker, :algolia, type: :worker do
  let(:user) { create(:user) }

  before do
    mock_requester = AlgoliaMockRequester.new
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
