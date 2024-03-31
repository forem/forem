require "rails_helper"

RSpec.describe ListingHelper do
  let!(:cat1) { create(:listing_category, cost: 1) }
  let!(:cat2) { create(:listing_category, :cfp, cost: 5) }

  describe "select_options_for_categories" do
    it "returns the correct options array" do
      expect(helper.select_options_for_categories).to match_array(
        [
          ["#{cat1.name} (1 Credit)", cat1.slug, cat1.id],
          ["#{cat2.name} (5 Credits)", cat2.slug, cat2.id],
        ],
      )
    end
  end

  describe "categories_for_display" do
    it "return the correct hash of slug and name pairs" do
      expect(helper.categories_for_display).to match_array(
        [
          { slug: cat1.slug, name: cat1.name },
          { slug: cat2.slug, name: cat2.name },
        ],
      )
    end
  end

  describe "categories_available" do
    it "returns a hash with slugs as keys" do
      expected = [cat1.slug.to_sym, cat2.slug.to_sym]
      expect(helper.categories_available.keys).to match_array(expected)
    end

    it "categories have the correct keys" do
      cfp_category = helper.categories_available[:cfp]
      expect(cfp_category.keys).to match_array(%i[cost name rules])
    end
  end
end
