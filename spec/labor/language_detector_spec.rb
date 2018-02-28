require 'rails_helper'

RSpec.describe LanguageDetector do
  let(:user) { create(:user) }
  let(:article) { create(:article, user_id: user.id) }
  it "Should return language" do
    expect(LanguageDetector.new(article).detect).to eq("en")
  end
end
