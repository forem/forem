require "rails_helper"

RSpec.describe Search::Listing, type: :service do
  describe "::search_documents", elasticsearch: "Listing" do
    let(:listing) { create(:listing) }

    it "parses listing document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    context "with a query" do
      # listing_search is a copy_to field including:
      # body_markdown, location, slug, tags, and title
      it "searches by listing_search" do
        listing1 = create(:listing, body_markdown: "# body_markdown with test")
        listing2 = create(:listing, location: "a test location")
        listing3 = create(:listing, title: "this test title is testing slug")
        listing4 = create(:listing, tag_list: ["test"])
        listing5 = create(:listing, title: "a test title")
        listings = [listing1, listing2, listing3, listing4, listing5]
        index_documents(listings)

        listing_docs = described_class.search_documents(params: { size: 5, listing_search: "test" })
        expect(listing_docs.count).to eq(5)
        expect(listing_docs.map { |t| t["id"] }).to match_array(listings.map(&:id))
      end
    end

    context "with a term filter" do
      it "searches by category" do
        new_category = create(:listing_category, :cfp)
        listing.update(listing_category_id: new_category.id)
        index_documents(listing)
        params = { size: 5, category: new_category.slug }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by contact_via_connect" do
        listing.update(contact_via_connect: true)
        index_documents(listing)
        params = { size: 5, contact_via_connect: true }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by location" do
        listing.update(location: "a location")
        index_documents(listing)
        params = { size: 5, location: "location" }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by slug" do
        slug_listing = create(:listing, title: "A slug is created from this title in a callback")
        index_documents(slug_listing)
        params = { size: 5, slug: "slug" }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(slug_listing.id)
      end

      it "searches by tags" do
        listing.update(tag_list: %w[beginners career])
        index_documents(listing)
        params = { size: 5, tags: "career" }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by title" do
        listing.update(title: "An Amazing Title")
        index_documents(listing)
        params = { size: 5, title: "amazing" }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by user_id" do
        index_documents(listing)
        params = { size: 5, user_id: listing.user_id }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by bumped_at" do
        listing.update(bumped_at: 1.day.from_now)
        index_documents(listing)
        params = { size: 5, bumped_at: { gt: Time.current } }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end

      it "searches by expires_at" do
        listing.update(expires_at: 1.day.ago)
        index_documents(listing)
        params = { size: 5, expires_at: { lt: Time.current } }

        listing_docs = described_class.search_documents(params: params)
        expect(listing_docs.count).to eq(1)
        expect(listing_docs.first["id"]).to eq(listing.id)
      end
    end

    it "sorts documents for a given field" do
      listing = create(:listing)
      cfp = create(:listing_category, :cfp)
      listing2 = create(:listing, listing_category_id: cfp.id)
      index_documents([listing, listing2])
      params = { size: 5, sort_by: "category", sort_direction: "asc" }

      listing_docs = described_class.search_documents(params: params)
      expect(listing_docs.count).to eq(2)
      expect(listing_docs.first["id"]).to eq(listing2.id)
      expect(listing_docs.last["id"]).to eq(listing.id)
    end

    it "sorts documents by bumped_at by default" do
      listing.update(bumped_at: 1.year.ago)
      listing2 = create(:listing, bumped_at: Time.current)
      index_documents([listing, listing2])
      params = { size: 5 }

      listing_docs = described_class.search_documents(params: params)
      expect(listing_docs.count).to eq(2)
      expect(listing_docs.first["id"]).to eq(listing2.id)
      expect(listing_docs.last["id"]).to eq(listing.id)
    end

    it "paginates the results" do
      listing.update(bumped_at: 1.year.ago)
      listing2 = create(:listing, bumped_at: Time.current)
      index_documents([listing, listing2])
      first_page_params = { page: 0, per_page: 1, sort_by: "bumped_at", order: "dsc" }

      listing_docs = described_class.search_documents(params: first_page_params)
      expect(listing_docs.first["id"]).to eq(listing2.id)

      second_page_params = { page: 1, per_page: 1, sort_by: "bumped_at", order: "dsc" }

      listing_docs = described_class.search_documents(params: second_page_params)
      expect(listing_docs.first["id"]).to eq(listing.id)
    end

    it "returns an empty Array if no results are found" do
      jobs_category = create(:listing_category, :jobs)
      listing.update(listing_category: jobs_category)

      cfp_category = create(:listing_category, :cfp)
      listing2 = create(:listing,
                        listing_category: cfp_category)
      index_documents([listing, listing2])
      params = { page: 3, per_page: 1 }

      listing_docs = described_class.search_documents(params: params)
      expect(listing_docs).to eq([])
    end
  end
end
