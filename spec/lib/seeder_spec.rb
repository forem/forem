require "rails_helper"

RSpec.describe Seeder, type: :lib do
  describe "#create_if_none" do
    let(:seeder) { described_class.new }

    it "returns existing records when class data already exists" do
      user = create(:user)

      result = seeder.create_if_none(User, 10) do
        raise "create_if_none should not execute the block when records exist"
      end

      expect(result).to be_a(ActiveRecord::Relation)
      expect(result).to include(user)
    end
  end
end
