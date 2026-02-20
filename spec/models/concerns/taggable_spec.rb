require "rails_helper"

RSpec.describe Taggable, type: :model do
  describe "#sync_tags_array" do
    it "syncs cached_tag_list string to tags_array before saving" do
      article = build(:article, tags: "ruby, rails, testing")
      # Forem often overrides `tags=` which might set `cached_tag_list` behind the scenes, or maybe we can set it directly.
      article.cached_tag_list = "ruby, rails, testing"
      
      expect { article.save! }.to change { article.tags_array }.from([]).to(["ruby", "rails", "testing"])
    end

    it "handles empty tags" do
      article = build(:article)
      article.cached_tag_list = ""
      
      article.save!
      expect(article.reload.tags_array).to eq([])
    end

    it "handles nil tags" do
      article = build(:article)
      article.cached_tag_list = nil
      
      article.save!
      expect(article.reload.tags_array).to eq([])
    end
    
    it "removes whitespace from tags" do
      article = build(:article)
      article.cached_tag_list = " ruby , rails  "
      
      article.save!
      expect(article.reload.tags_array).to eq(["ruby", "rails"])
    end
  end
end
