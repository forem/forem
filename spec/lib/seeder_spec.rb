require "rails_helper"

RSpec.describe Seeder do
  subject(:seeder) { described_class.new }

  describe "#create_if_none" do
    it "returns nil when records already exist" do
      create(:user)
      result = seeder.create_if_none(User) { raise "should not run" }
      expect(result).to be_nil
    end

    it "yields and returns the block value when no records exist" do
      User.delete_all
      result = seeder.create_if_none(User) { "block_value" }
      expect(result).to eq("block_value")
    end
  end
end
