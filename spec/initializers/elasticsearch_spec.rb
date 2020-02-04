require "rails_helper"

describe Elasticsearch do
  it "creates a search client that talks to Elasticsearch" do
    expect(SearchClient).to be_instance_of(Elasticsearch::Transport::Client)
    expect(SearchClient.info.dig("tagline")).to eq("You Know, for Search")
  end
end
