require "rails_helper"

RSpec.describe Search::QueryBuilders::ChatChannelMembership, type: :service do
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
  end

  describe "#as_hash" do
    it "applies FILTER_KEYS from params" do
      params = { channel_status: "active", channel_type: "direct", user_id: 1 }
      filter = described_class.new(params: params)
      expected_filters = [
        { "term" => { "channel_status" => "active" } },
        { "term" => { "channel_type" => "direct" } },
        { "terms" => { "status" => %w[active joining_request] } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "applies QUERY_KEYS from params" do
      params = { channel_text: "a_name" }
      query = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "a_name*", "fields" => [:channel_text], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(query.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
    end

    it "applies QUERY_KEYS and FILTER_KEYS from params" do
      params = { channel_text: "a_name", channel_status: "active", user_id: 1 }
      query = described_class.new(params: params)
      expected_query = [{
        "simple_query_string" => {
          "query" => "a_name*", "fields" => [:channel_text], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expected_filters = [
        { "term" => { "channel_status" => "active" } },
        { "terms" => { "status" => %w[active joining_request] } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(query.as_hash.dig("query", "bool", "must")).to match_array(expected_query)
      expect(query.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "always applies viewable_by and status params" do
      params = { user_id: 1 }
      filter = described_class.new(params: params)
      expected_filters = [
        { "terms" => { "status" => %w[active joining_request] } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "always applies channel discoverable and status params" do
      allow(Settings::Mascot).to receive(:mascot_user_id).and_return(2)

      params = { user_id: Settings::Mascot.mascot_user_id }
      filter = described_class.new(params: params)
      expected_filters = [
        { "terms" => { "status" => %w[active joining_request] } },
        { "terms" => { "viewable_by" => Settings::Mascot.mascot_user_id } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "ignores params we dont support" do
      params = { not_supported: "direct", user_id: 1 }
      filter = described_class.new(params: params)
      expected_filters = [
        { "terms" => { "status" => %w[active joining_request] } },
        { "terms" => { "viewable_by" => 1 } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(expected_filters)
    end

    it "sets default params when not present" do
      filter = described_class.new(params: {})
      expect(filter.as_hash["sort"]).to eq("channel_last_message_at" => "desc")
      expect(filter.as_hash["size"]).to eq(0)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "status", sort_direction: "asc", size: 20 }
      filter = described_class.new(params: params)
      expect(filter.as_hash["sort"]).to eq("status" => "asc")
      expect(filter.as_hash["size"]).to eq(20)
    end
  end
end
