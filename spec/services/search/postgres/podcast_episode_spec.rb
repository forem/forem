require "rails_helper"

# rubocop:disable RSpec/ExampleLength
RSpec.describe Search::Postgres::PodcastEpisode, type: :service do
  let(:podcast_episode) { create(:podcast_episode) }

  describe "::search_documents" do
    context "when filtering PodcastEpisodes" do
      it "does not include PodcastEpisodes from Podcasts that are unpublished", :aggregate_failures do
        body_text = "DHH talks about how Ruby on Rails rocks!"
        published_podcast = create(:podcast, published: true)
        unpublished_podcast = create(:podcast, published: false)

        published_podcast_episode = create(
          :podcast_episode,
          body: body_text,
          processed_html: body_text,
          podcast_id: published_podcast.id,
        )

        unpublished_podcast_episode = create(
          :podcast_episode,
          body: body_text,
          processed_html: body_text,
          podcast_id: unpublished_podcast.id,
        )

        result = described_class.search_documents(term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).not_to include(unpublished_podcast_episode.search_id)
        expect(ids).to include(published_podcast_episode.search_id)
      end

      it "does not include PodcastEpisodes that are not reachable", :aggregate_failures do
        body_text = "DHH talks about how Ruby on Rails rocks!"
        podcast = create(:podcast, published: true)

        reachable_podcast_episode = create(
          :podcast_episode,
          body: body_text,
          processed_html: body_text,
          podcast_id: podcast.id,
          reachable: true,
        )

        unreachable_podcast_episode = create(
          :podcast_episode,
          body: body_text,
          processed_html: body_text,
          podcast_id: podcast.id,
          reachable: false,
        )

        result = described_class.search_documents(term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).not_to include(unreachable_podcast_episode.search_id)
        expect(ids).to include(reachable_podcast_episode.search_id)
      end
    end

    context "when describing the result format" do
      let(:result) { described_class.search_documents(term: podcast_episode.body) }

      it "returns the correct attributes for the result" do
        expected_keys = %i[
          id body_text comments_count path published_at quote reactions_count
          subtitle summary title website_url class_name highlight hotness_score
          main_image podcast public_reactions_count published search_score slug
          user
        ]

        expect(result.first.keys).to match_array(expected_keys)
      end

      it "returns the correct attributes for the podcast" do
        expected_keys = %i[slug image_url title]
        podcast = result.first[:podcast]
        expect(podcast.keys).to match_array(expected_keys)

        expect(podcast[:slug]).to eq(podcast_episode.podcast_slug)

        image_url = Images::Profile.call(podcast_episode.podcast.profile_image_url, length: 90)
        expect(podcast[:image_url]).to eq(image_url)

        expect(podcast[:title]).to eq(podcast_episode.title)
      end

      it "orders the results by published_at in descending order" do
        body_text = "DHH talks about how Ruby on Rails rocks!"
        podcast_episode = create(:podcast_episode, body: body_text, processed_html: body_text)
        older_podcast_episode = create(:podcast_episode, body: body_text, processed_html: body_text,
                                                         published_at: 1.day.ago)

        result = described_class.search_documents(sort_by: "published_at", sort_direction: "desc", term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to eq([podcast_episode.search_id, older_podcast_episode.search_id])
      end

      it "orders the results by published_at (created_at) in ascending order" do
        body_text = "DHH talks about how Ruby on Rails rocks!"
        podcast_episode = create(:podcast_episode, body: body_text, processed_html: body_text)
        older_podcast_episode = create(:podcast_episode, body: body_text, processed_html: body_text,
                                                         published_at: 1.day.ago)

        result = described_class.search_documents(sort_by: "published_at", sort_direction: "asc", term: "rails")
        # rubocop:disable Rails/PluckId
        ids = result.pluck(:id)
        # rubocop:enable Rails/PluckId

        expect(ids).to eq([older_podcast_episode.search_id, podcast_episode.search_id])
      end
    end

    context "when searching for a term" do
      it "matches against the podcast episode's body (body_text)", :aggregate_failures do
        body_text = "DHH talks about how Ruby on Rails rocks!"
        podcast_episode.update_columns(body: body_text, processed_html: body_text)
        result = described_class.search_documents(term: "rails")

        expect(result.first[:body_text]).to eq podcast_episode.body_text

        result = described_class.search_documents(term: "javascript")
        expect(result).to be_empty
      end

      it "matches against the podcast episode's title", :aggregate_failures do
        podcast_episode.update_columns(title: "What's new in RoR?")
        result = described_class.search_documents(term: "RoR")

        expect(result.first[:title]).to eq podcast_episode.title

        result = described_class.search_documents(term: "javascript")
        expect(result).to be_empty
      end

      it "matches against the podcast episode's subtitle", :aggregate_failures do
        podcast_episode.update_columns(subtitle: "DHH's latest thoughts")
        result = described_class.search_documents(term: "DHH")

        expect(result.first[:subtitle]).to eq podcast_episode.subtitle

        result = described_class.search_documents(term: "javascript")
        expect(result).to be_empty
      end
    end

    context "when paginating" do
      before { create_list(:podcast_episode, 2) }

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
# rubocop:enable RSpec/ExampleLength
