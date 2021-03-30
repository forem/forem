require "rails_helper"

RSpec.describe Search::Postgres::Listing, type: :service do
  let(:listing) { create(:listing) }

  describe "::search_documents" do
    it "does not include a listing that is unpublished", :aggregate_failures do
      published_listing = create(:listing, title: "Published Listing", published: true)
      unpublished_listing = create(:listing, title: "Unpublished Listing", published: false)
      result = described_class.search_documents(term: "Listing")
      titles = result.pluck(:title)

      expect(titles).not_to include(unpublished_listing.title)
      expect(titles).to include(published_listing.title)
    end

    context "when describing the result format" do
      let(:result) { described_class.search_documents(term: listing.title) }

      it "returns the correct attributes for the result" do
        expected_keys = %i[
          id body_markdown bumped_at category contact_via_connect expires_at
          originally_published_at location processed_html published slug title
          user_id tags author
        ]

        expect(result.first.keys).to match_array(expected_keys)
      end

      it "returns the correct attributes for the author" do
        expected_keys = %i[username name profile_image_90]
        expect(result.first[:author].keys).to match_array(expected_keys)
      end

      it "returns tag as an Array" do
        expect(result.first[:tags]).to be_an_instance_of(Array)
      end
    end

    context "when searching for a term" do
      it "matches against the listing's body_markdown", :aggregate_failures do
        listing.update_columns(body_markdown: "A Sweet New Opportunity")
        result = described_class.search_documents(term: "new")

        expect(result.first[:body_markdown]).to eq listing.body_markdown

        result = described_class.search_documents(term: "old")
        expect(result).to be_empty
      end

      it "matches against the listing's cached_tag_list", :aggregate_failures do
        listing.update_columns(cached_tag_list: "javascript, beginners, ruby")
        result = described_class.search_documents(term: "beginner")

        expect(result.first[:tags].join(", ")).to eq listing.cached_tag_list

        result = described_class.search_documents(term: "newbie")
        expect(result).to be_empty
      end

      it "matches against the listing's location", :aggregate_failures do
        listing.update_columns(location: "Tampa")
        result = described_class.search_documents(term: "tampa")

        expect(result.first[:location]).to eq listing.location

        result = described_class.search_documents(term: "milan")
        expect(result).to be_empty
      end

      it "matches against the listing's slug", :aggregate_failures do
        listing.update_columns(slug: "some-cool-slug")
        result = described_class.search_documents(term: "cool")

        expect(result.first[:slug]).to eq listing.slug

        result = described_class.search_documents(term: "lame")
        expect(result).to be_empty
      end

      it "matches against the listing's title", :aggregate_failures do
        listing.update_columns(title: "Awesome New Listing")
        result = described_class.search_documents(term: "new")

        expect(result.first[:title]).to eq listing.title

        result = described_class.search_documents(term: "old")
        expect(result).to be_empty
      end
    end

    context "when searching for a term and filtering by category" do
      it "selects results with the requested category" do
        job_listings_category = create(:listing_category, name: "Job Listings", slug: "jobs")

        job_listing = create(:listing,
                             title: "Looking for a Ruby on Rails Developer!",
                             listing_category: job_listings_category)

        education_category = create(:listing_category, name: "Education/Courses", slug: "education")

        listing.update_columns(
          title: "New Ruby on Rails for Beginners Course!",
          classified_listing_category_id: education_category.id,
        )

        result = described_class.search_documents(term: "Ruby on Rails", category: job_listing.category)
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to include(job_listing.id)
        expect(ids).not_to include(listing.id)
      end
    end

    context "when paginating" do
      before { create_list(:listing, 2) }

      it "returns no results when out of pagination bounds" do
        result = described_class.search_documents(page: 99)
        expect(result).to be_empty
      end

      it "returns paginated results", :aggregate_failures do
        result = described_class.search_documents(page: 0, per_page: 1)
        expect(result.length).to eq(1)

        result = described_class.search_documents(page: 1, per_page: 1)
        expect(result.length).to eq(1)
      end
    end
  end
end
