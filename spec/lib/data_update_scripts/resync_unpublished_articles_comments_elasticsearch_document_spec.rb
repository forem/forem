require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210118194138_resync_unpublished_articles_comments_elasticsearch_document.rb",
)

describe DataUpdateScripts::ResyncUnpublishedArticlesCommentsElasticsearchDocument do
  it "works" do
    article = create(:article)
    comment = create(:comment, commentable: article)
    sidekiq_perform_enqueued_jobs
    article.update_column(:published, false)

    sidekiq_assert_enqueued_with(job: Search::IndexWorker, args: ["Comment", comment.id]) do
      described_class.new.run
    end
  end
end
