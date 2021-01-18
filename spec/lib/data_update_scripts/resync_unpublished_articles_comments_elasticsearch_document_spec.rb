require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20210118194138_resync_unpublished_articles_comments_elasticsearch_document.rb",
)

describe DataUpdateScripts::ResyncUnpublishedArticlesCommentsElasticsearchDocument do
  it "works" do
    sidekiq_perform_enqueued_jobs { described_class.new.run }
  end
end
