require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200519142908_re_index_feed_content_and_users_to_elasticsearch.rb")

describe DataUpdateScripts::ReIndexFeedContentAndUsersToElasticsearch, elasticsearch: "User" do
  it "indexes users to Elasticsearch" do
    user = create(:user)
    expect { user.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    sidekiq_perform_enqueued_jobs { described_class.new.run }
    expect(user.elasticsearch_doc).not_to be_nil

    expect(user.elasticsearch_doc["_source"].keys).to include "public_reactions_count"
  end
end
