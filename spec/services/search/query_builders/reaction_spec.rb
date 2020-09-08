require "rails_helper"

RSpec.describe Search::QueryBuilders::Reaction, type: :service do
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

    it "sets category to readinglist" do
      filter = described_class.new(params: {})
      expect(filter.params).to include(category: "readinglist")
    end
  end

  describe "#as_hash" do
    let(:query_fields) { described_class::QUERY_KEYS[:search_fields] }

    it "applies QUERY_KEYS from params" do
      params = { search_fields: "test" }
      filter = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "test",
          "fields" => query_fields,
          "lenient" => true,
          "analyze_wildcard" => true,
          "minimum_should_match" => 2
        }
      }]
      expect(search_bool_clause(filter)["must"]).to match_array(expected_query)
    end

    it "applies TERM_KEYS from params" do
      params = { tag_names: "beginner", user_id: 777, status: "valid" }
      filter = described_class.new(params: params)
      expected_filters = [
        { "terms" => { "status" => ["valid"] } },
        { "terms" => { "reactable.tags.name" => ["beginner"] } },
        { "terms" => { "user_id" => [777] } },
        { "terms" => { "category" => ["readinglist"] } },
      ]
      expect(search_bool_clause(filter)["filter"]).to match_array(expected_filters)
    end

    it "applies QUERY_KEYS and TERM_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { search_fields: "ruby", tag_names: "cfp" }
        filter = described_class.new(params: params)
        expected_query = [{
          "simple_query_string" => { "query" => "ruby", "fields" => query_fields, "lenient" => true,
                                     "analyze_wildcard" => true, "minimum_should_match" => 2 }
        }]
        expected_filters = [
          { "terms" => { "reactable.tags.name" => ["cfp"] } },
          { "terms" => { "category" => ["readinglist"] } },
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
      params = { sort_by: "status", sort_direction: "asc", size: 20 }
      filter = described_class.new(params: params).as_hash
      expect(filter["sort"]).to eq("status" => "asc")
      expect(filter["size"]).to eq(20)
    end
  end

  def search_bool_clause(query_builder)
    query_builder.as_hash.dig("query", "bool")
  end
end
