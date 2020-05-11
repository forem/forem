require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200410152018_resync_elasticsearch_documents.rb")

describe DataUpdateScripts::ResyncElasticsearchDocuments, elasticsearch: %w[FeedContent User Tag] do
  after do
    Article::SEARCH_CLASS.refresh_index
    User::SEARCH_CLASS.refresh_index
  end

  it "indexes podcast episodes and tags to Elasticsearch" do
    tag = create(:tag)
    podcast_episode = create(:podcast_episode)
    Sidekiq::Worker.clear_all

    expect { tag.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)
    expect { podcast_episode.elasticsearch_doc }.to raise_error(Search::Errors::Transport::NotFound)

    sidekiq_perform_enqueued_jobs { described_class.new.run }
    expect(tag.elasticsearch_doc).not_to be_nil
    expect(podcast_episode.elasticsearch_doc).not_to be_nil
  end

  it "syncs articles, comments, and users to Elasticsearch", :aggregate_failures do
    article = create(:article)
    comment = create(:comment)
    user = create(:user)
    index_real_and_mock_documents(article, comment, user)

    expect(Article::SEARCH_CLASS.articles_document_count).not_to eq(Article.count)
    expect(Comment::SEARCH_CLASS.comments_document_count).not_to eq(Comment.count)
    expect(User::SEARCH_CLASS.document_count).not_to eq(User.count)

    sidekiq_perform_enqueued_jobs { described_class.new.run }
    refresh_indexes

    expect(article.elasticsearch_doc).not_to be_nil
    expect(user.elasticsearch_doc).not_to be_nil
    expect(comment.elasticsearch_doc).not_to be_nil
    expect(Article::SEARCH_CLASS.articles_document_count).to eq(Article.count)
    expect(Comment::SEARCH_CLASS.comments_document_count).to eq(Comment.count)
    expect(User::SEARCH_CLASS.document_count).to eq(User.count)
  end

  def index_real_and_mock_documents(article, comment, user)
    sidekiq_perform_enqueued_jobs
    Article::SEARCH_CLASS.index("article_#{article.id + 100}", class_name: "Article")
    Comment::SEARCH_CLASS.index("comment_#{comment.id + 100}", class_name: "Comment")
    User::SEARCH_CLASS.index(user.id + 100, name: "User")
    refresh_indexes
  end

  def refresh_indexes
    User::SEARCH_CLASS.refresh_index
    Article::SEARCH_CLASS.refresh_index
  end
end
