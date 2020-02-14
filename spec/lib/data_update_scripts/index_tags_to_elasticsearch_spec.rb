require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200214171607_index_tags_to_elasticsearch.rb")

describe DataUpdateScripts::IndexTagsToElasticsearch do
  it "indexes tags to Elasticsearch" do
    tag = FactoryBot.create(:tag)
    expect(tag).to respond_to(:index_to_elasticsearch_inline)
    allow(Tag).to receive(:find_each)
    described_class.new.run
    expect(Tag).to have_received(:find_each) { [tag] }
  end
end
