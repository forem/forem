require "rails_helper"

RSpec.describe Articles::SuggestStickies, type: :service do
  let(:article) { create(:article, published: true, cached_tag_list: "ruby") }
  let!(:other_article) { create(:article, published: true, cached_tag_list: "career", public_reactions_count: 50, published_at: 1.day.ago) }

  describe ".call" do
    it "returns articles with limited attributes including cached_user" do
      # SuggestStickies uses career as a suggestion tag
      result = described_class.call(article)
      expect(result).not_to be_empty
      
      stickie = result.first
      expect { stickie.path }.not_to raise_error
      expect { stickie.title }.not_to raise_error
      expect { stickie.cached_tag_list }.not_to raise_error
      expect { stickie.cached_user }.not_to raise_error
      
      # Verify that we DON'T have body_markdown
      expect { stickie.body_markdown }.to raise_error(ActiveModel::MissingAttributeError)
    end
  end
end
