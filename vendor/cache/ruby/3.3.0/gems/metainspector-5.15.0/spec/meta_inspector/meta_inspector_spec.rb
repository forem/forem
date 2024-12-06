require 'spec_helper'

describe MetaInspector do
  it "returns a Document" do
    expect(MetaInspector.new('http://example.com').class).to eq(MetaInspector::Document)
  end

  it "cache request" do
    # Creates a memory cache (a Hash that responds to #read, #write and #delete)
    cache = Hash.new
    def cache.read(k) self[k]; end
    def cache.write(k, v) self[k] = v; end

    MetaInspector.new('http://example.com', faraday_http_cache: { store: cache })

    expect(cache.keys).not_to be_empty
  end
end
