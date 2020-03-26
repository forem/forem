require "rails_helper"

RSpec.describe Search::ClassifiedListing, type: :service, elasticsearch: true do
  describe "::search_documents" do
    let(:classified_listing) { create(:classified_listing) }

    it "parses classified_listing document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      # classified_listing_search is a copy_to field including:
      # body_markdown, location, slug, tags, and title
      it "searches by classified_listing_search" do
        classified_listing1 = create(:classified_listing, body_markdown: "# body_markdown with test")
        classified_listing2 = create(:classified_listing, location: "a test location")
        classified_listing3 = create(:classified_listing, title: "this test title is testing slug")
        classified_listing4 = create(:classified_listing, tag_list: ["test"])
        classified_listing5 = create(:classified_listing, title: "a test title")
        classified_listings = [classified_listing1, classified_listing2, classified_listing3, classified_listing4, classified_listing5]
        index_documents(classified_listings)

        classified_listing_docs = described_class.search_documents(params: { size: 5, classified_listing_search: "test" })
        expect(classified_listing_docs.count).to eq(5)
        expect(classified_listing_docs.map { |t| t.dig("id") }).to match_array(classified_listings.map(&:id))
      end
    end

    context "with a term filter" do
      it "searches by category" do
        classified_listing.update(category: "forhire")
        index_documents(classified_listing)
        params = { size: 5, category: "forhire" }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by contact_via_connect" do
        classified_listing.update(contact_via_connect: true)
        index_documents(classified_listing)
        params = { size: 5, contact_via_connect: true }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by location" do
        classified_listing.update(location: "a location")
        index_documents(classified_listing)
        params = { size: 5, location: "location" }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by slug" do
        slug_classified_listing = FactoryBot.create(:classified_listing, title: "A slug is created from this title in a callback")
        index_documents(slug_classified_listing)
        params = { size: 5, slug: "slug" }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(slug_classified_listing.id)
      end

      it "searches by tags" do
        classified_listing.update(tag_list: %w[beginners career])
        index_documents(classified_listing)
        params = { size: 5, tags: "career" }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by title" do
        classified_listing.update(title: "An Amazing Title")
        index_documents(classified_listing)
        params = { size: 5, title: "amazing" }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by user_id" do
        index_documents(classified_listing)
        params = { size: 5, user_id: classified_listing.user_id }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by bumped_at" do
        classified_listing.update(bumped_at: 1.day.from_now)
        index_documents(classified_listing)
        params = { size: 5, bumped_at: { gt: Time.current } }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end

      it "searches by expires_at" do
        classified_listing.update(expires_at: 1.day.ago)
        index_documents(classified_listing)
        params = { size: 5, expires_at: { lt: Time.current } }

        classified_listing_docs = described_class.search_documents(params: params)
        expect(classified_listing_docs.count).to eq(1)
        expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
      end
    end

    it "sorts documents for a given field" do
      classified_listing.update(category: "forhire")
      classified_listing2 = FactoryBot.create(:classified_listing, category: "cfp")
      index_documents([classified_listing, classified_listing2])
      params = { size: 5, sort_by: "category", sort_direction: "asc" }

      classified_listing_docs = described_class.search_documents(params: params)
      expect(classified_listing_docs.count).to eq(2)
      expect(classified_listing_docs.first["id"]).to eq(classified_listing2.id)
      expect(classified_listing_docs.last["id"]).to eq(classified_listing.id)
    end

    it "sorts documents by bumped_at by default" do
      classified_listing.update(bumped_at: 1.year.ago)
      classified_listing2 = FactoryBot.create(:classified_listing, bumped_at: Time.current)
      index_documents([classified_listing, classified_listing2])
      params = { size: 5 }

      classified_listing_docs = described_class.search_documents(params: params)
      expect(classified_listing_docs.count).to eq(2)
      expect(classified_listing_docs.first["id"]).to eq(classified_listing2.id)
      expect(classified_listing_docs.last["id"]).to eq(classified_listing.id)
    end

    it "paginates the results" do
      classified_listing.update(bumped_at: 1.year.ago)
      classified_listing2 = FactoryBot.create(:classified_listing, bumped_at: Time.current)
      index_documents([classified_listing, classified_listing2])
      first_page_params = { page: 0, per_page: 1, sort_by: "bumped_at", order: "dsc" }

      classified_listing_docs = described_class.search_documents(params: first_page_params)
      expect(classified_listing_docs.first["id"]).to eq(classified_listing2.id)

      second_page_params = { page: 1, per_page: 1, sort_by: "bumped_at", order: "dsc" }

      classified_listing_docs = described_class.search_documents(params: second_page_params)
      expect(classified_listing_docs.first["id"]).to eq(classified_listing.id)
    end

    it "returns an empty Array if no results are found" do
      classified_listing.update(category: "forhire")
      classified_listing2 = FactoryBot.create(:classified_listing, category: "cfp")
      index_documents([classified_listing, classified_listing2])
      params = { page: 3, per_page: 1 }

      classified_listing_docs = described_class.search_documents(params: params)
      expect(classified_listing_docs).to eq([])
    end
  end
end
