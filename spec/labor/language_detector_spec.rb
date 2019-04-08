require "rails_helper"

RSpec.describe LanguageDetector do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  let(:article_1) { create(:article, user_id: user.id) }
  let(:article_2) { create(:article, user_id: user.id) }

  it "detects english" do
    article.update_column(:body_markdown, "This is definitely english.")
    article.update_column(:title, "I love the english language.")
    expect(described_class.new(article).detect).to eq("en")
  end
  it "detects french" do
    article_1.update_column(:body_markdown, "C'est vraiment francais, bien oui?")
    article_1.update_column(:title, "C'est vraiment francais, bien oui?")
    expect(described_class.new(article_1).detect).to eq("fr")
  end
  it "detects nil if non-sensicle" do
    article_2.update_column(:body_markdown, "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec pharetra sapien orci, sit amet auctor nunc tempor quis.")
    article_2.update_column(:title, "Mauris commodo felis et lacus volutpat fermentum.")
    expect(described_class.new(article_2).detect).to eq(nil)
  end
end
