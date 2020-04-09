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
  end
end
