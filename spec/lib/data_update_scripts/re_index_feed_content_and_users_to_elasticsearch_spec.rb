require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200519142908_re_index_feed_content_and_users_to_elasticsearch.rb")

describe DataUpdateScripts::ReIndexFeedContentAndUsersToElasticsearch do
  after do
    Search::FeedContent.refresh_index
  end

  it "indexes feed content(articles, comments, podcast episodes) and users to Elasticsearch", :aggregate_failures do
    article = create(:article)
    podcast_episode = create(:podcast_episode)
    comment = create(:comment)

    expect { article.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    expect { podcast_episode.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    expect { comment.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }

    expect(article.elasticsearch_doc).not_to be_nil
    expect(podcast_episode.elasticsearch_doc).not_to be_nil
    expect(comment.elasticsearch_doc).not_to be_nil

    expect(article.elasticsearch_doc["_source"].keys).to include "public_reactions_count"
    expect(podcast_episode.elasticsearch_doc["_source"].keys).to include "public_reactions_count"
    expect(comment.elasticsearch_doc["_source"].keys).to include "public_reactions_count"
  end
end
