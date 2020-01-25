require "rails_helper"

RSpec.describe Reactions::FetchArticlesService, type: :service do
  let(:size) { 3 }
  let(:page) { 0 }
  let(:user) { create(:user) }
  let(:articles) { create_list(:article, size) }

  describe "#call" do
    context "when reactions occur to multiple articles" do
      before do
        articles.each do |article|
          create(:reaction, reactable: article, user: user)
        end
      end

      it "returns the number of reactions" do
        stories = described_class.call(user, page, size)
        expect(stories.size).to eq size
      end
    end

    context "when multiple reactions occur to same article" do
      before do
        article = articles[0]
        create(:reaction, reactable: article, user: user, category: "like")
        create(:reaction, reactable: article, user: user, category: "unicorn")
      end

      it "returns only one copy of the reaction" do
        stories = described_class.call(user, page, size)
        expect(stories.size).to eq 1
      end
    end
  end
end
