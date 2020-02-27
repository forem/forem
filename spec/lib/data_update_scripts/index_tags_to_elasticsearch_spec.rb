require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200214171607_index_tags_to_elasticsearch.rb")

describe DataUpdateScripts::IndexTagsToElasticsearch, elasticsearch: true do
  it "indexes tags to Elasticsearch" do
    tag = FactoryBot.create(:tag)
    expect { tag.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    described_class.new.run
    expect(tag.elasticsearch_doc).not_to be_nil
  end
end
