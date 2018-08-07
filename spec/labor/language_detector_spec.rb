require "rails_helper"

RSpec.describe LanguageDetector do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }

  it "returns language" do
    expect(described_class.new(article).detect).to eq("en")
  end
end
