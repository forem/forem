require "rails_helper"

RSpec.describe Search::QueryBuilders::ClassifiedListing, type: :service do
  describe "::intialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(filter_params)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new({})
      expect(filter.body).not_to be_nil
    end
  end

  describe "#as_hash" do
    it "applies TERM_KEYS from params" do
      params = { category: "cfp", tags: ["beginner"], contact_via_connect: false }
      filter = described_class.new(params)
      exepcted_filters = [
        { "term" => { "category" => "cfp" } },
        { "term" => { "tags" => ["beginner"] } },
        { "term" => { "contact_via_connect" => false } },
        { "term" => { "published" => true } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
    end

    it "applies RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { bumped_at: Time.current, expires_at: 1.day.from_now }
        filter = described_class.new(params)
        exepcted_filters = [
          { "range" => { "bumped_at" => Time.current } },
          { "range" => { "expires_at" => 1.day.from_now } },
          { "term" => { "published" => true } },
        ]
        expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
      end
    end

    it "applies QUERY_KEYS from params" do
      params = { classified_listing_search: "test" }
      filter = described_class.new(params)
      exepcted_query = [{
        "simple_query_string" => {
          "query" => "test*", "fields" => [:classified_listing_search], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(exepcted_query)
    end

    it "applies QUERY_KEYS, TERM_KEYS, and RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { classified_listing_search: "test", bumped_at: Time.current, category: "cfp" }
        filter = described_class.new(params)
        exepcted_query = [{
          "simple_query_string" => { "query" => "test*", "fields" => [:classified_listing_search], "lenient" => true, "analyze_wildcard" => true }
        }]
        exepcted_filters = [
          { "range" => { "bumped_at" => Time.current } },
          { "term" => { "category" => "cfp" } },
          { "term" => { "published" => true } },
        ]
        expect(filter.as_hash.dig("query", "bool", "must")).to match_array(exepcted_query)
        expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
      end
    end

    it "ignores params we don't support" do
      params = { not_supported: "trash", category: "cfp" }
      filter = described_class.new(params)
      exepcted_filters = [
        { "term" => { "category" => "cfp" } },
        { "term" => { "published" => true } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
    end

    it "sets default params when not present" do
      filter = described_class.new({}).as_hash
      expect(filter.dig("sort")).to eq("bumped_at" => "desc")
      expect(filter.dig("size")).to eq(0)
      expect(filter.dig("query", "bool", "filter")).to match_array([{ "term" => { "published" => true } }])
    end

    it "allows default params to be overriden" do
      params = { sort_by: "category", sort_direction: "asc", size: 20 }
      filter = described_class.new(params).as_hash
      expect(filter.dig("sort")).to eq("category" => "asc")
      expect(filter.dig("size")).to eq(20)
    end
  end
end
