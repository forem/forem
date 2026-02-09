require "rails_helper"

RSpec.describe Articles::GetUserStickies, type: :service do
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, published: true, cached_tag_list: "ruby") }
  let!(:other_articles) { create_list(:article, 3, user: user, published: true, cached_tag_list: "ruby") }

  describe ".call" do
    it "returns articles with limited attributes needed by _sticky_nav" do
      result = described_class.call(article, user)
      expect(result).not_to be_empty

      sticky = result.first
      # Columns explicitly selected for _sticky_nav partial:
      expect { sticky.id }.not_to raise_error
      expect { sticky.path }.not_to raise_error
      expect { sticky.title }.not_to raise_error
      expect { sticky.cached_tag_list }.not_to raise_error
      expect { sticky.organization_id }.not_to raise_error
      expect { sticky.user_id }.not_to raise_error
      expect { sticky.subforem_id }.not_to raise_error
    end

    it "allows decorating for cached_tag_list_array (used in view)" do
      result = described_class.call(article, user)
      sticky = result.first
      # _sticky_nav calls article.decorate.cached_tag_list_array
      expect { sticky.decorate.cached_tag_list_array }.not_to raise_error
      expect(sticky.decorate.cached_tag_list_array).to be_a(Array)
    end

    it "excludes the current article" do
      result = described_class.call(article, user)
      expect(result.map(&:id)).not_to include(article.id)
    end

    it "does not load unnecessary columns (proves optimization)" do
      result = described_class.call(article, user)
      sticky = result.first
      expect { sticky.body_markdown }.to raise_error(ActiveModel::MissingAttributeError)
      expect { sticky.processed_html }.to raise_error(ActiveModel::MissingAttributeError)
    end

    it "handles article with nil cached_tag_list" do
      article.update_column(:cached_tag_list, nil)
      result = described_class.call(article.reload, user)
      # Should not raise, just returns empty or unfiltered results
      expect(result).to be_a(ActiveRecord::Relation)
    end
  end
end
