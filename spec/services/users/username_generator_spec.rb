require "rails_helper"

RSpec.describe Users::UsernameGenerator, type: :service do
  let(:user) { build(:user) }

  it "returns randomly generated username if empty list is passed" do
    expect(described_class.call([""])).to be_present
  end

  it "returns supplied username if does not exist" do
    expect(described_class.call(["foo"])).to eq("foo")
  end

  it "returns modified username" do
    expect(described_class.call(["foo.bar"])).to eq("foobar")
  end

  it "returns randomly generated username" do
    expect(described_class.call).to be_present
  end

  context "when username already exists" do
    before { user.save! }

    it "returns supplied username with suffix if exists" do
      expect(described_class.call([user.username])).to match(/#{user.username}_\d/)
    end

    it "returns nil if all generation methods are exhausted" do
      username_generator = -> { user.username }
      result = described_class.call([], generator: username_generator)
      expect(result).to be_nil
    end
  end
end
