require "rails_helper"

RSpec.describe Article do
  describe "series ID alias registration" do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    it "creates a legacy alias when collection ID changes for same slug and user" do
      original_collection = create(:collection, user: user, slug: "stable-series", organization: nil)
      migrated_collection = create(:collection, user: user, slug: "stable-series", organization: organization)
      article = create(:article, user: user, with_collection: original_collection)

      article.update!(collection: migrated_collection, organization: organization)

      alias_record = CollectionIdAlias.find_by(legacy_collection_id: original_collection.id)
      expect(alias_record).to be_present
      expect(alias_record.collection_id).to eq(migrated_collection.id)
    end

    it "does not create alias when moving to a different series slug" do
      original_collection = create(:collection, user: user, slug: "series-one", organization: nil)
      different_collection = create(:collection, user: user, slug: "series-two", organization: organization)
      article = create(:article, user: user, with_collection: original_collection)

      article.body_markdown.gsub!("series: #{original_collection.slug}", "series: #{different_collection.slug}")
      article.update!(collection: different_collection, organization: organization)

      expect(CollectionIdAlias.find_by(legacy_collection_id: original_collection.id)).to be_nil
    end
  end
end
