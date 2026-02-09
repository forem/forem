require "rails_helper"

RSpec.describe Articles::GetUserStickies, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, cached_tag_list: "ruby") }
  let!(:other_article) { create(:article, user: user, published: true, cached_tag_list: "ruby") }

  describe ".call" do
    it "returns articles with limited attributes" do
      result = described_class.call(article, user)
      expect(result).to include(other_article)
      
      # Verify limited attributes don't raise error for what we need
      expect { result.first.path }.not_to raise_error
      expect { result.first.title }.not_to raise_error
      expect { result.first.cached_tag_list }.not_to raise_error
      
      # Verify that we DON'T have body_markdown (to prove optimization works)
      expect { result.first.body_markdown }.to raise_error(ActiveModel::MissingAttributeError)
    end
  end
end
