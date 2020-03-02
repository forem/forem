require "rails_helper"

RSpec.describe Search::QueryBuilders::ChatChannelMembership, type: :service do
  describe "::initialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(filter_params, 1)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new({}, 1)
      expect(filter.body).not_to be_nil
    end
  end

  describe "#as_hash" do
    it "applies FILTER_KEYS from params" do
      params = { channel_status: "active", channel_type: "direct" }
      filter = described_class.new(params, 1)
      expected_filters = [
        { "term" => { "channel_status" => "active" } },
        { "term" => { "channel_type" => "direct" } },
        { "term" => { "status" => "active" } },
        { "term" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "applies QUERY_KEYS from params" do
      params = { channel_text: "a_name" }
      query = described_class.new(params, 1)
      expected_query = [{
        "simple_query_string" => {
          "query" => "a_name*", "fields" => [:channel_text], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(query.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
    end

    it "applies QUERY_KEYS and FILTER_KEYS from params" do
      params = { channel_text: "a_name", channel_status: "active" }
      query = described_class.new(params, 1)
      expected_query = [{
        "simple_query_string" => {
          "query" => "a_name*", "fields" => [:channel_text], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expected_filters = [{ "term" => { "channel_status" => "active" } }, { "term" => { "viewable_by" => 1 } }, { "term" => { "status" => "active" } }]
      expect(query.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
      expect(query.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "always applies viewable_by and status params" do
      params = {}
      filter = described_class.new(params, 1)
      expected_filters = [
        { "term" => { "status" => "active" } },
        { "term" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "ignores params we dont support" do
      params = { not_supported: "direct" }
      filter = described_class.new(params, 1)
      expected_filters = [
        { "term" => { "status" => "active" } },
        { "term" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "sets default params when not present" do
      filter = described_class.new({}, 1)
      expect(filter.as_hash.dig("sort")).to eq("channel_last_message_at" => "desc")
      expect(filter.as_hash.dig("size")).to eq(0)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "status", sort_direction: "asc", size: 20 }
      filter = described_class.new(params, 1)
      expect(filter.as_hash.dig("sort")).to eq("status" => "asc")
      expect(filter.as_hash.dig("size")).to eq(20)
    end
  end
end
