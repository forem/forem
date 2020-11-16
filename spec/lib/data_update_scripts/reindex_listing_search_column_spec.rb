require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200803142830_reindex_listing_search_column.rb")

describe DataUpdateScripts::ReindexListingSearchColumn, elasticsearch: "Listing" do
  it "indexes listings to Elasticsearch" do
    listing = create(:listing)
    expect { listing.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    described_class.new.run
    expect(listing.elasticsearch_doc).not_to be_nil
  end
end
