require "rails_helper"

RSpec.describe ArticleApiIndexService do
  describe "#get with a username" do
    let(:user) { create(:user) }

    it "uses the default page size" do
      relation = described_class.new(username: user.username).get

      expect(relation.limit_value).to eq(described_class::DEFAULT_PER_PAGE)
    end

    it "raises the page size to the API maximum when state=all is requested" do
      relation = described_class.new(username: user.username, state: "all").get

      expect(relation.limit_value).to be > described_class::DEFAULT_PER_PAGE
      expect(relation.limit_value).to eq(1000)
    end
  end
end
