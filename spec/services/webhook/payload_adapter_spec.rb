require "rails_helper"

RSpec.describe Webhook::PayloadAdapter, type: :service do
  it "raises an exception when invalid object is passed" do
    expect do
      described_class.new(User.new).hash
    end.to raise_error(Webhook::InvalidPayloadObject)
  end

  describe "#hash" do
    let(:user) { create(:user) }
    let!(:article) { create(:article, title: "I'm super", user: user) }

    it "returns a hash for a persisted article" do
      data = described_class.new(article).hash
      expect(data).to be_kind_of(Hash)
      expect(data[:data][:attributes][:title]).to eq(article.title)
      expect(data[:data][:attributes][:body_markdown]).to be_truthy
    end

    it "returns a hash with a user" do
      data = described_class.new(article).hash
      expect(data[:data][:attributes][:user][:data][:attributes][:username]).to eq(user.username)
    end

    it "returns a hash for a destroyed article" do
      article = create(:article, title: "hello")
      article.destroy
      data = described_class.new(article).hash
      expect(data).to be_kind_of(Hash)
      expect(data[:data][:attributes][:title]).to eq("hello")
      expect(data[:data][:attributes][:body_markdown]).to be_falsey
    end
  end
end
