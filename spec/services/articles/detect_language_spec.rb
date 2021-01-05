require "rails_helper"

RSpec.describe Articles::DetectLanguage, type: :service do
  let(:user) { create(:user) }
  let!(:article) { create(:article, user_id: user.id) }

  it "detects english" do
    allow(article).to receive(:title).and_return("I love the english language.")
    allow(article).to receive(:body_markdown).and_return("This is definitely english.")

    expect(described_class.call(article)).to eq("en")
  end

  it "detects french" do
    allow(article).to receive(:title).and_return("C'est vraiment francais, bien oui?")
    allow(article).to receive(:body_markdown).and_return("C'est vraiment francais, bien oui?")

    expect(described_class.call(article)).to eq("fr")
  end

  it "detects nil if non-sensicle" do
    allow(article).to receive(:title).and_return("Lorem ipsum dolor sit amet")
    allow(article).to receive(:body_markdown).and_return("consectetur adipiscing elit")

    expect(described_class.call(article)).to be(nil)
  end
end
