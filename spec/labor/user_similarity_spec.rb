require "rails_helper"

RSpec.describe UserSimilarity, vcr: {} do
  let(:user) { create(:user, summary: "I like ruby and JavaScript and Go") }
  let(:similar_user) { create(:user, summary: "I like JavaScript and Go") }
  let(:dissimilar_user) { create(:user, summary: "I like Haskell and functional programming") }

  it "returns similar user" do
    simialar_score = UserSimilarity.new(user, similar_user).score
    dissimialar_score = UserSimilarity.new(user, dissimilar_user).score
    expect(simialar_score).to be > dissimialar_score
  end

  it "Is not affected by stop words" do
    user.summary = user.summary + " throughout yourself can indeed otherwise thru yourselves through yours by inc others"
    dissimilar_user.summary = dissimilar_user.summary + " throughout yourself can indeed otherwise thru yourselves through yours by inc others"
    simialar_score = UserSimilarity.new(user, similar_user).score
    dissimialar_score = UserSimilarity.new(user, dissimilar_user).score
    expect(simialar_score).to be > dissimialar_score
  end

  it "Is affected by non-stop words" do
    user.mentee_description = "Hot dogs languages punk rock hello"
    dissimilar_user.mentor_description = "Hot dogs languages punk rock hello "
    simialar_score = UserSimilarity.new(user, similar_user).score
    dissimialar_score = UserSimilarity.new(user, dissimilar_user).score
    expect(simialar_score).to be < dissimialar_score
  end
end
