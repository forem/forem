require "rails_helper"

RSpec.describe ActsAsTaggableOn::Tag, type: :lib do
  describe "#after_commit" do
    it "on create indexes tag to elasticsearch" do
      tag_name = "muffintag"
      create(:article, body_markdown: "---\ntitle: Me#{rand(1000)}\ntags: #{tag_name}\n---\n\nMeMeMe")
      sidekiq_perform_enqueued_jobs
      tag = Tag.find_by(name: tag_name)
      expect(tag.elasticsearch_doc).not_to be_nil
    end

    it "syncs related elasticsearch documents" do
      article = create(:article)
      podcast_episode = create(:podcast_episode)
      tag = article.tags.first
      podcast_episode.tags << tag
      new_keywords = "keyword1, keyword2, keyword3"
      sidekiq_perform_enqueued_jobs

      tag.update(keywords_for_search: new_keywords)
      sidekiq_perform_enqueued_jobs
      expect(collect_keywords(article)).to include(new_keywords)
      expect(collect_keywords(podcast_episode)).to include(new_keywords)
    end
  end

  def collect_keywords(record)
    record.elasticsearch_doc.dig("_source", "tags").flat_map { |t| t["keywords_for_search"] }
  end
end
