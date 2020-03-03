require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200217215802_index_classified_listings_to_elasticsearch.rb")

describe DataUpdateScripts::IndexClassifiedListingsToElasticsearch, elasticsearch: true do
  it "indexes classified_listings to Elasticsearch" do
    classified_listing = create(:classified_listing)
    expect { classified_listing.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    described_class.new.run
    expect(classified_listing.elasticsearch_doc).not_to be_nil
  end
end
