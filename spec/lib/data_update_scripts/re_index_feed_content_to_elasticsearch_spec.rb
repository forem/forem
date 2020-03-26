require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200326145114_re_index_feed_content_to_elasticsearch.rb")

describe DataUpdateScripts::ReIndexFeedContentToElasticsearch, elasticsearch: true do
  it "indexes feed content(articles, comments, podcast episodes) to Elasticsearch" do
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
  end
end
