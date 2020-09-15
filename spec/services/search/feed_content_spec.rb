require "rails_helper"

RSpec.describe Search::FeedContent, type: :service do
  it "defines INDEX_NAME, INDEX_ALIAS, and MAPPINGS", :aggregate_failures do
    expect(described_class::INDEX_NAME).not_to be_nil
    expect(described_class::INDEX_ALIAS).not_to be_nil
    expect(described_class::MAPPINGS).not_to be_nil
  end

  describe "::search_documents", elasticsearch: "FeedContent" do
    let(:article1) { create(:article, published_at: 1.day.ago) }
    let(:article2) { create(:article, published_at: 2.days.ago) }
    let(:article3) { create(:article, published_at: Time.current) }

    it "parses feed content document hits from search response" do
      mock_search_response = { "hits" => { "hits" => {} } }
      allow(described_class).to receive(:search) { mock_search_response }
      described_class.search_documents(params: {})
      expect(described_class).to have_received(:search).with(body: a_kind_of(Hash))
    end

    it "returns highlighted fields" do
      allow(article1).to receive(:body_text).and_return("I love ruby")
      allow(article2).to receive(:body_text).and_return("Ruby Tuesday is love")
      index_documents([article1, article2])
      query_params = { size: 5, search_fields: "love ruby" }

      feed_docs = described_class.search_documents(params: query_params)
      expect(feed_docs.count).to eq(2)
      doc_highlights = feed_docs.map { |t| t.dig("highlight", "body_text") }.flatten
      expect(doc_highlights).to include("I <mark>love</mark> <mark>ruby</mark>",
                                        "<mark>Ruby</mark> Tuesday is <mark>love</mark>")
    end

    it "returns fields necessary for the view" do
      allow(article1).to receive(:flare_tag).and_return(name: "help", bg_color_hex: nil, text_color_hex: nil)
      view_keys = %w[
        id title path class_name cloudinary_video_url comments_count flare_tag tag_list user_id user
        published_at_int published_timestamp readable_publish_date
      ]
      flare_tag_keys = %w[name bg_color_hex text_color_hex]
      user_keys = %w[username name profile_image_90]
      podcast_keys = %w[slug image_url title]
      index_documents([article1])

      feed_doc = described_class.search_documents(params: { size: 1 }).first
      expect(feed_doc.keys).to include(*view_keys)
      expect(feed_doc["user"].keys).to include(*user_keys)
      expect(feed_doc["flare_tag"].keys).to include(*flare_tag_keys)
      expect(feed_doc["podcast"].keys).to include(*podcast_keys)
    end

    context "with chronological sorting specified" do
      before do
        allow(article1).to receive(:title).and_return("Ruby Slippers")
        allow(article2).to receive(:title).and_return("Ruby Tuesday")
        allow(article3).to receive(:title).and_return("Just Ruby")
      end

      it "sorts articles from newest to oldest" do
        index_documents([article1, article2, article3])
        query_params = { size: 5, search_fields: "ruby", sort_by: "published_at", sort_direction: "desc" }

        titles_in_order = described_class.search_documents(params: query_params).map { |doc| doc["title"] }

        expect(titles_in_order).to eq ["Just Ruby", "Ruby Slippers", "Ruby Tuesday"]
      end

      it "sorts articles from oldest to newest" do
        index_documents([article1, article2, article3])
        query_params = { size: 5, search_fields: "ruby", sort_by: "published_at", sort_direction: "asc" }

        titles_in_order = described_class.search_documents(params: query_params).map { |doc| doc["title"] }

        expect(titles_in_order).to eq ["Ruby Tuesday", "Ruby Slippers", "Just Ruby"]
      end
    end

    context "with a query" do
      it "searches by search_fields" do
        allow(article1).to receive(:title).and_return("ruby")
        allow(article2).to receive(:body_text).and_return("Ruby Tuesday")
        index_documents([article1, article2])
        query_params = { size: 5, search_fields: "ruby" }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(2)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article1.id, article2.id)
      end

      # Skipped because this seems inconsistent
      xit "bumps scores for words closer together" do
        allow(article1).to receive(:body_text).and_return("Ruby I dont know maybe is cool")
        allow(article2).to receive(:body_text).and_return("Ruby is cool I dont know maybe")
        index_documents([article1, article2])
        query_params = { size: 5, search_fields: "ruby is cool" }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(2)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to eq([article2.id, article1.id])
      end
    end

    context "with a filter term" do
      it "filters by tag names" do
        article1.tags << create(:tag, name: "ruby")
        article2.tags << create(:tag, name: "python")
        index_documents([article1, article2])
        query_params = { size: 5, tag_names: "ruby" }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article1.id)
      end

      it "filters by user_id" do
        index_documents([article1, article2])
        query_params = { size: 5, user_id: article1.user_id }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article1.id)
      end

      it "filters by approved" do
        article1.update(approved: false)
        article2.update(approved: true)
        index_documents([article1, article2])
        query_params = { size: 5, approved: true }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article2.id)
      end

      it "filters by class_name" do
        pde = create(:podcast_episode)
        index_documents([pde, article1, article2])
        query_params = { size: 5, class_name: "PodcastEpisode" }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(pde.id)
      end

      it "filters by id" do
        index_documents([article1, article2])
        query_params = { size: 5, id: ["article_#{article1.id}"] }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article1.id)
        expect(doc_ids).not_to include(article2.id)
      end
    end

    context "with range keys" do
      it "searches by published_at" do
        article1.update(published_at: 1.year.ago)
        article2.update(published_at: 1.month.ago)
        index_documents([article1, article2])
        query_params = { size: 5, published_at: { gte: 2.months.ago.iso8601 } }

        feed_docs = described_class.search_documents(params: query_params)
        expect(feed_docs.count).to eq(1)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to include(article2.id)
      end
    end

    context "with default sorting" do
      it "sorts by Elasticsearch _score which is weighted based on article score" do
        ruby_tag = create(:tag, name: "ruby")
        allow(article1).to receive(:score).and_return(200)
        article1.tags << ruby_tag
        allow(article2).to receive(:score).and_return(1500)
        article2.tags << ruby_tag
        index_documents([article1, article2])
        query_params = { size: 5, search_fields: "ruby" }

        feed_docs = described_class.search_documents(params: query_params)
        doc_ids = feed_docs.map { |t| t["id"] }
        expect(doc_ids).to eq([article2.id, article1.id])
      end
    end
  end

  describe "document counts", elasticsearch: "FeedContent" do
    it "returns counts for each document class" do
      article = create(:article)
      comment = create(:comment)
      pde = create(:podcast_episode)
      index_documents([article, comment, pde])
      described_class::INCLUDED_CLASS_NAMES.each do |class_name|
        expect(described_class.public_send("#{class_name.underscore.pluralize}_document_count")).to eq(1)
      end
    end
  end
end
