require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200519142908_re_index_feed_content_and_users_to_elasticsearch.rb")

describe DataUpdateScripts::ReIndexFeedContentAndUsersToElasticsearch do
  after do
    Search::FeedContent.refresh_index
    Search::User.refresh_index
  end

  it "indexes feed(articles) to Elasticsearch" do
    article = create(:article)

    expect { article.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }

    expect(article.elasticsearch_doc).not_to be_nil
    expect(article.elasticsearch_doc["_source"].keys).to include("public_reactions_count")
  end

  it "indexes feed(podcast episodes) to Elasticsearch" do
    podcast_episode = create(:podcast_episode)

    expect { podcast_episode.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }

    expect(podcast_episode.elasticsearch_doc).not_to be_nil
    expect(podcast_episode.elasticsearch_doc["_source"].keys).to include("public_reactions_count")
  end

  it "indexes feed(comments) to Elasticsearch" do
    comment = create(:comment)

    expect { comment.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }

    expect(comment.elasticsearch_doc).not_to be_nil

    expect(comment.elasticsearch_doc["_source"].keys).to include("public_reactions_count")
  end

  it "indexes users to Elasticsearch" do
    user = create(:user)

    expect { user.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }

    expect(user.elasticsearch_doc).not_to be_nil

    expect(user.elasticsearch_doc["_source"].keys).to include("public_reactions_count")
  end
end
