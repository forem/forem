require "rails_helper"

RSpec.describe CouponGenerator, vcr: {} do
  let(:versions) { ["member_discount", "sticker_pack", "tee_pack"] }

  describe "#expect" do
    it "generates code with proper prefix ( [version]_[code] )" do
      VCR.use_cassette "coupon_generator_1" do
        version = versions.sample
        expect(described_class.new(1, version).generate).to include("#{version}_")
      end
    end
  end
end
