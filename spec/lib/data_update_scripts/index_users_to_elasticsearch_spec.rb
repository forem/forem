require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200313123108_index_users_to_elasticsearch.rb")

describe DataUpdateScripts::IndexUsersToElasticsearch, elasticsearch: true do
  it "indexes users to Elasticsearch" do
    user = create(:user)
    expect { user.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    sidekiq_perform_enqueued_jobs { described_class.new.run }
    expect(user.elasticsearch_doc).not_to be_nil
  end
end
