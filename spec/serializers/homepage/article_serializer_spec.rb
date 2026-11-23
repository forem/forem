require "rails_helper"

RSpec.describe Homepage::ArticleSerializer, type: :serializer do
  describe "#serialized_collection_from" do
    let(:user) { create(:user, name: "\"Rowdy\" Roddy Piper \\:/") }
    let(:organization) { create(:organization) }
    let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
    let(:article) { create(:article, user: user, organization: organization, tags: tag.name) }

    before do
      article
      stub_const("FlareTag::FLARE_TAG_IDS_HASH", { "ama" => tag.id })
    end

    it "is parseable as JSON (once converted to_json)" do
      response = described_class.serialized_collection_from(relation: Article.all)
      expect(JSON.parse(response.to_json)[0].dig("user", "name")).to eq(user.name)
    end

    it "includes who favorited the article" do
      leader = create(:user)
      article.update_columns(favorited_by_user_id: leader.id, favorited_at: Time.current)

      response = described_class.serialized_collection_from(relation: Article.all)

      expect(response.first[:favorited_by_user_id]).to eq(leader.id)
    end

    it "reports no favoriter for unfavorited articles" do
      response = described_class.serialized_collection_from(relation: Article.all)

      expect(response.first[:favorited_by_user_id]).to be_nil
    end

    it "reads reaction counts for all articles in one cache round-trip" do
      other_article = create(:article, user: user)
      create(:reaction, reactable: article, category: "like")
      create(:reaction, reactable: other_article, category: "unicorn")
      allow(Rails.cache).to receive(:read_multi).and_call_original
      allow(Rails.cache).to receive(:fetch).and_call_original

      response = described_class.serialized_collection_from(relation: Article.order(:id))

      expect(response.map { |a| a[:public_reaction_categories].map { |c| c.slug.to_s } }).to eq([%w[like], %w[unicorn]])
      expect(Rails.cache).to have_received(:read_multi)
        .with(a_string_starting_with("reaction_counts_for_reactable"), any_args).once
      expect(Rails.cache).not_to have_received(:fetch).with(/reaction_counts_for_reactable/, anything)
    end

    it "queries articles only once and avoids LEFT OUTER JOIN reactions when serializing Homepage::ArticlesQuery" do
      relation = Homepage::ArticlesQuery.call(sort_by: :hotness_score, sort_direction: :desc)
      article_queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        article_queries << sql if sql.include?('FROM "articles"') && !payload[:cached]
      end

      response = nil
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        response = described_class.serialized_collection_from(relation: relation)
      end

      expect(response.size).to eq(1)
      expect(article_queries.size).to eq(1)
      expect(article_queries.first).not_to include('LEFT OUTER JOIN "reactions"')
    end

    it "preloads only required user and organization columns instead of SELECT *" do
      other_article = create(
        :article,
        user: create(:user),
        organization: create(:organization),
      )
      queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        queries << sql if (sql.include?('FROM "users"') || sql.include?('FROM "organizations"')) && !payload[:cached]
      end

      response = nil
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        response = described_class.serialized_collection_from(
          relation: Article.where(id: [article.id, other_article.id]).order(:id),
        )
      end

      expect(queries.size).to eq(2)
      expect(queries).to all(exclude('SELECT "users".*', 'SELECT "organizations".*'))
      expect(response.size).to eq(2)
      expect(response.first[:user]).to eq(
        name: user.name,
        profile_image_90: user.profile_image_90,
        username: user.username,
      )
      expect(response.first[:organization]).to eq(
        name: organization.name,
        profile_image_90: organization.profile_image_90,
        slug: organization.slug,
      )
    end
  end

  describe ".serialized_json_from" do
    let(:user) { create(:user, name: "\"Rowdy\" Roddy Piper \\:/") }
    let(:organization) { create(:organization) }
    let(:tag) { create(:tag, name: "ama", bg_color_hex: "#f3f3f3", text_color_hex: "#cccccc") }
    let(:article) do
      create(:article, user: user, organization: organization, tags: tag.name,
                       video_thumbnail_url: "https://example.com/thumb.jpg")
    end

    before do
      article
      create(:reaction, reactable: article, category: "like")
      create(:reaction, reactable: article, category: "unicorn")
    end

    it "matches serialized_collection_from JSON output identically without hydrating Article models",
       :aggregate_failures do
      native_result = nil
      allow(ForemNative).to receive(:serialize_homepage_articles_json).and_wrap_original do |m, *args|
        native_result = m.call(*args)
      end

      relation = Homepage::ArticlesQuery.call(sort_by: :hotness_score, sort_direction: :desc)
      encoded = described_class.serialized_json_from(relation: relation)

      expect(encoded).to be_a(described_class::EncodedJson)
      expect(ForemNative).to have_received(:serialize_homepage_articles_json).once
      expect(native_result).to be_a(String)

      expected_rel = Homepage::ArticlesQuery.call(sort_by: :hotness_score, sort_direction: :desc)
      expected = JSON.parse({ result: described_class.serialized_collection_from(relation: expected_rel) }.to_json)
      expect(JSON.parse(encoded.to_str)).to eq(expected)
    end

    it "selects the first flare tag in article tag order matching serialized_collection_from", :aggregate_failures do
      discuss_tag = create(:tag, name: "discuss", bg_color_hex: "#112233", text_color_hex: "#ffffff")
      multi_flare = create(:article, user: user, tags: "#{discuss_tag.name}, #{tag.name}")

      alone_expected = JSON.parse(
        { result: described_class.serialized_collection_from(relation: Article.where(id: multi_flare.id)) }.to_json,
      )
      alone_json = described_class.serialized_json_from(relation: Article.where(id: multi_flare.id)).to_str
      alone_actual = JSON.parse(alone_json)
      expect(alone_actual).to eq(alone_expected)
      expect(alone_actual.dig("result", 0, "flare_tag", "name")).to eq("discuss")

      pair_ids = [multi_flare.id, article.id]
      pair_expected_rel = Article.where(id: pair_ids).order(:id)
      pair_expected = JSON.parse(
        { result: described_class.serialized_collection_from(relation: pair_expected_rel) }.to_json,
      )
      pair_actual = JSON.parse(
        described_class.serialized_json_from(relation: Article.where(id: pair_ids).order(:id)).to_str,
      )
      expect(pair_actual).to eq(pair_expected)
    end

    it "returns an empty result JSON immediately for empty relations" do
      encoded = described_class.serialized_json_from(relation: Article.none)
      expect(encoded.to_str).to eq('{"result":[]}')
    end

    it "falls back transparently for status articles, non-English locales, and eager-loading joins",
       :aggregate_failures do
      allow(ForemNative).to receive(:serialize_homepage_articles_json).and_call_original

      status_article = create(:article, user: user, type_of: "status", body_markdown: "", main_image: nil)
      status_article.update!(published: true, title: "Quick status\nupdate")

      expected = JSON.parse(
        { result: described_class.serialized_collection_from(relation: Article.where(id: status_article.id)) }.to_json,
      )
      actual = JSON.parse(described_class.serialized_json_from(relation: Article.where(id: status_article.id)).to_str)
      expect(actual).to eq(expected)
      expect(actual["result"].first).to include("title_finalized_for_feed", "title_for_metadata")

      I18n.with_locale(:fr) do
        fr_expected = JSON.parse(
          { result: described_class.serialized_collection_from(relation: Article.where(id: article.id)) }.to_json,
        )
        fr_actual = JSON.parse(described_class.serialized_json_from(relation: Article.where(id: article.id)).to_str)
        expect(fr_actual).to eq(fr_expected)
      end

      eager_expected = JSON.parse(
        { result: described_class.serialized_collection_from(
          relation: Article.includes(:organization).where(organizations: { id: organization.id }),
        ) }.to_json,
      )
      eager_actual = JSON.parse(
        described_class.serialized_json_from(
          relation: Article.includes(:organization).where(organizations: { id: organization.id }),
        ).to_str,
      )
      expect(eager_actual).to eq(eager_expected)
      expect(ForemNative).not_to have_received(:serialize_homepage_articles_json)
    end
  end
end
