require "rails_helper"

RSpec.describe Users::UsernameGenerator, type: :service do
  let(:user) { create(:user) }

  it "returns randomly generated username if empty list is passed" do
    expect(described_class.call([""])).to be_present
  end

  it "returns supplied username if does not exist" do
    expect(described_class.call(["foo"])).to eq("foo")
  end

  it "returns modified username" do
    expect(described_class.call(["foo.bar"])).to eq("foobar")
  end

  it "returns supplied username with suffix if exists" do
    expect(described_class.call([user.username])).to start_with("#{user.username}_")
  end

  it "returns randomly generated username" do
    expect(described_class.call).to be_present
  end

  it "returns nil if all generation methods are exhausted" do
    username_generator = described_class.new
    allow(username_generator).to receive(:random_letters).and_return(user.username)
    expect(username_generator.call).to be_nil
  end
end
