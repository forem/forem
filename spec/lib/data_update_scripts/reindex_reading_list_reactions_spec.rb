require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200901194251_reindex_reading_list_reactions.rb")

describe DataUpdateScripts::ReindexReadingListReactions, elasticsearch: "Reaction" do
  it "indexes feed content(articles, comments, podcast episodes) to Elasticsearch" do
    reactions = create_list(:reaction, 3, category: "readinglist")
    Sidekiq::Worker.clear_all

    reactions.each do |reaction|
      expect { reaction.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    end

    sidekiq_perform_enqueued_jobs { described_class.new.run }
    reactions.each do |reaction|
      expect(reaction.elasticsearch_doc).not_to be_nil
    end
  end
end
