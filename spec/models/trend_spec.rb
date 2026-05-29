require "rails_helper"

RSpec.describe Trend, type: :model do
  let(:embedding) { Array.new(768, 0.1) }

  describe "slug generation" do
    it "generates a parameterized slug from the name on create" do
      trend = create(:trend, name: "Evolution of Hermes Agents", centroid_embedding: embedding)
      expect(trend.slug).to eq("evolution-of-hermes-agents")
    end

    it "adds a counter suffix if the slug is already taken" do
      create(:trend, name: "Hermes Agents", centroid_embedding: embedding)
      trend2 = create(:trend, name: "Hermes Agents", centroid_embedding: embedding)
      expect(trend2.slug).to eq("hermes-agents-1")
    end

    it "updates the slug when the name changes on update" do
      trend = create(:trend, name: "Hermes Agents", centroid_embedding: embedding)
      expect(trend.slug).to eq("hermes-agents")

      trend.update!(name: "Self-Improving Hermes Agents")
      expect(trend.slug).to eq("self-improving-hermes-agents")
    end

    it "does not change the slug if the name does not change on update" do
      trend = create(:trend, name: "Hermes Agents", centroid_embedding: embedding)
      original_slug = trend.slug

      trend.update!(description: "Updated description of the trend")
      expect(trend.slug).to eq(original_slug)
    end

    it "adds counter suffix on update if name changes to an existing slug" do
      create(:trend, name: "Hermes Agents", centroid_embedding: embedding)
      trend2 = create(:trend, name: "Other Trend", centroid_embedding: embedding)

      trend2.update!(name: "Hermes Agents")
      expect(trend2.slug).to eq("hermes-agents-1")
    end
  end
end
