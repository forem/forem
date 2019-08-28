require "rails_helper"

RSpec.describe UserSimilarity, vcr: {} do
  let(:user) { create(:user, summary: "I like ruby and JavaScript and Go") }
  let(:similar_user) { create(:user, summary: "I like JavaScript and Go") }
  let(:dissimilar_user) { create(:user, summary: "I like Haskell and functional programming") }

  it "returns similar user" do
    similar_score = described_class.new(user, similar_user).score
    dissimilar_score = described_class.new(user, dissimilar_user).score
    expect(similar_score).to be > dissimilar_score
  end

  it "Is not affected by stop words" do
    user.summary = user.summary + " throughout yourself can indeed otherwise thru yourselves through yours by inc others"
    dissimilar_user.summary = dissimilar_user.summary + " throughout yourself can indeed otherwise thru yourselves through yours by inc others"
    similar_score = described_class.new(user, similar_user).score
    dissimilar_score = described_class.new(user, dissimilar_user).score
    expect(similar_score).to be > dissimilar_score
  end

  it "Is affected by non-stop words" do
    user.summary = "Hot dogs languages punk rock hello"
    dissimilar_user.summary = "Hot dogs languages punk rock hello "
    similar_score = described_class.new(user, similar_user).score
    dissimilar_score = described_class.new(user, dissimilar_user).score
    expect(similar_score).to be < dissimilar_score
  end
end
