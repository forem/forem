require "rails_helper"

RSpec.describe CouponGenerator, vcr: {} do
  let(:versions) { %w[member_discount sticker_pack tee_pack] }

  describe "#expect" do
    it "generates code with proper prefix ( [version]_[code] )" do
      version = versions.sample
      expect(described_class.new(1, version).generate).to include("#{version}_")
    end
  end
end
