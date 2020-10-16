require "rails_helper"

RSpec.describe Search::QueryBuilders::FeedContent, type: :service do
  describe "::initialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(params: filter_params)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new(params: {})
      expect(filter.body).not_to be_nil
    end

    it "builds query body with html encoder" do
      filter = described_class.new(params: {})
      expect(filter.body).to include("highlight" => hash_including("encoder" => "html"))
    end

    it "sets published to true" do
      filter = described_class.new(params: {})
      expect(filter.params).to include(published: true)
    end
  end

  describe "#as_hash" do
    let(:query_fields) { described_class::QUERY_KEYS[:search_fields] }
    let(:expected_query) do
      [{
        "simple_query_string" => {
          "query" => "test",
          "fields" => query_fields,
          "lenient" => true,
          "analyze_wildcard" => true,
          "minimum_should_match" => 2
        }
      }]
    end
    let(:expected_match_phrase) do
      [{
        "match_phrase" => {
          "search_fields" => {
            "query" => "test",
            "slop" => 0
          }
        }
      }]
    end

    it "applies QUERY_KEYS from params" do
      params = { search_fields: "test" }
      filter = described_class.new(params: params)
      expect(search_bool_clause(filter)["must"]).to match_array(expected_query)
      expect(search_bool_clause(filter)["should"]).to match_array(expected_match_phrase)
      expect(search_bool_clause(filter)["minimum_should_match"]).to eq(0)
    end

    it "applies TERM_KEYS from params" do
      params = { approved: true, tag_names: "beginner", user_id: 777, class_name: "Article" }
      filter = described_class.new(params: params)
      expected_filters = [
        { "terms" => { "approved" => [true] } },
        { "terms" => { "tags.name" => ["beginner"] } },
        { "terms" => { "user.id" => [777] } },
        { "terms" => { "class_name" => ["Article"] } },
        { "terms" => { "published" => [true] } },
      ]
      expect(search_bool_clause(filter)["filter"]).to match_array(expected_filters)
    end

    it "applies RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { published_at: { lte: Time.current } }
        filter = described_class.new(params: params)
        expected_filters = [
          { "range" => { "published_at" => { lte: Time.current } } },
          { "terms" => { "published" => [true] } },
        ]
        expect(search_bool_clause(filter)["filter"]).to match_array(expected_filters)
      end
    end

    it "applies QUERY_KEYS, TERM_KEYS, and RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { search_fields: "ruby", published_at: { lte: Time.current }, tag_names: "cfp" }
        filter = described_class.new(params: params)
        expected_query = [{
          "simple_query_string" => { "query" => "ruby", "fields" => query_fields, "lenient" => true,
                                     "analyze_wildcard" => true, "minimum_should_match" => 2 }
        }]
        expected_filters = [
          { "range" => { "published_at" => { lte: Time.current } } },
          { "terms" => { "tags.name" => ["cfp"] } },
          { "terms" => { "published" => [true] } },
        ]
        expect(search_bool_clause(filter)["must"]).to match_array(expected_query)
        expect(search_bool_clause(filter)["filter"]).to match_array(expected_filters)
      end
    end

    it "ignores params we don't support" do
      params = { not_supported: "trash", search_fields: "cfp" }
      filter = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "cfp", "fields" => query_fields, "lenient" => true,
          "analyze_wildcard" => true, "minimum_should_match" => 2
        }
      }]
      expect(search_bool_clause(filter)["must"]).to match_array(expected_query)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "published_at", sort_direction: "asc", size: 20 }
      filter = described_class.new(params: params).as_hash
      expect(filter["sort"]).to eq("published_at" => "asc")
      expect(filter["size"]).to eq(20)
    end

    it "correctly sets default sort" do
      filter = described_class.new(params: {}).as_hash
      expect(filter["sort"]).to eq(described_class::DEFAULT_PARAMS[:sort])
    end
  end

  def search_bool_clause(query_builder)
    query_builder.as_hash.dig("query", "function_score", "query", "bool")
  end
end
