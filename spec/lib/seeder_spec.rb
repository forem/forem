require "rails_helper"

RSpec.describe Seeder, type: :lib do
  subject(:seeder) { described_class.new }

  describe "#create_if_none" do
    # The contract relied on by db/seeds.rb: when records already exist, the
    # block is skipped and the call returns nil — not the value the block
    # would have returned. Regression for #23104, where seeds.rb assigned
    # this nil to `users_in_random_order` and later called `.limit` on it.
    it "returns nil when records exist (block is skipped)" do
      create(:user)

      result = seeder.create_if_none(User) { User.order(Arel.sql("RANDOM()")) }

      expect(result).to be_nil
    end

    it "yields and returns the block's value when no records exist" do
      User.delete_all

      result = seeder.create_if_none(User) { :sentinel }

      expect(result).to eq(:sentinel)
    end
  end

  describe "#create_if_doesnt_exist" do
    it "yields when no record matches the attribute" do
      yielded = false

      seeder.create_if_doesnt_exist(User, "email", "no-such-user@forem.local") do
        yielded = true
      end

      expect(yielded).to be(true)
    end

    it "skips the block when a record matches the attribute" do
      user = create(:user)
      yielded = false

      seeder.create_if_doesnt_exist(User, "email", user.email) do
        yielded = true
      end

      expect(yielded).to be(false)
    end
  end
end
