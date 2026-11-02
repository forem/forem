require "spec_helper"
require_relative "../../../lib/local_redis/runtime"

RSpec.describe LocalRedis::Runtime do
  [nil, "", "0", "1"].each do |marker|
    it "selects L1 only with an explicit web marker (#{marker.inspect}) and socket URL" do
      stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_URL" => "unix:///tmp/cache.sock", "LOCAL_REDIS_ACTIVE" => marker))
      expect(described_class.active?).to eq(marker == "1")
    end
  end

  it "keeps the default store without a socket URL even with a marker" do
    stub_const("ENV", ENV.to_h.merge("LOCAL_REDIS_ACTIVE" => "1", "LOCAL_REDIS_URL" => ""))
    expect(described_class.active?).to be(false)
  end
end
