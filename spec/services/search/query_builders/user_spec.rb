require "rails_helper"

RSpec.describe Search::QueryBuilders::User, type: :service do
  describe "::intialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(params: filter_params)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new(params: {})
      expect(filter.body).not_to be_nil
    end
  end

  describe "#as_hash" do
    it "applies QUERY_KEYS from params" do
      params = { search_fields: "test" }
      filter = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "test*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
    end

    it "applies EXCLUDED_TERM_KEYS by default" do
      filter = described_class.new(params: {})
      expected_filters = [
        { "terms" => { "roles" => %w[suspended banned] } },
      ]
      expect(filter.as_hash.dig("query", "bool", "must_not")).to match_array(expected_filters)
    end

    it "applies EXCLUDED_TERM_KEYS and QUERY_KEYS" do
      params = { search_fields: "test" }
      filter = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "test*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expected_filters = [
        { "terms" => { "roles" => %w[suspended banned] } },
      ]
      expect(filter.as_hash.dig("query", "bool", "must_not")).to match_array(expected_filters)
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
    end

    it "ignores params we don't support" do
      params = { not_supported: "trash", search_fields: "cfp" }
      filter = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "cfp*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "name", sort_direction: "asc", size: 20 }
      filter = described_class.new(params: params).as_hash
      expect(filter["sort"]).to eq("name" => "asc")
      expect(filter["size"]).to eq(20)
    end
  end
end
