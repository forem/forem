require "rails_helper"

# This spec uses `pluck` on an array of hashes, but Rubocop can't tell the difference.
RSpec.describe Search::Organization, type: :service do
  describe "::search_documents" do
    it "returns an empty result if there are no orgnizations" do
      expect(described_class.search_documents).to be_empty
    end

    context "when searching for a term" do
      let(:organization) { create(:organization) }

      it "matches against the organization's name", :aggregate_failures do
        organization.update_columns(name: "Life of the party")

        result = described_class.search_documents(term: "party").first
        expect(result[:name]).to eq(organization.name)

        results = described_class.search_documents(term: "fiesta")
        expect(results).to be_empty
      end
    end
  end
end
