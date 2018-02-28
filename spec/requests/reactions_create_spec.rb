require "rails_helper"

RSpec.describe "ReactionsCreate", type: :request do
  let(:user) { create(:user) }

  before do
    @article = create(:article, user_id: user.id)
    sign_in user
  end

  it "creates reaction" do
    post "/reactions", params: {reactable_id: @article.id, reactable_type: "Article", category: "like"}
    expect(Reaction.last.reactable_id).to eq(@article.id)
  end

  it "destroys existing reaction" do
    post "/reactions", params: {reactable_id: @article.id, reactable_type: "Article", category: "like"}
    post "/reactions", params: {reactable_id: @article.id, reactable_type: "Article", category: "like"}
    expect(Reaction.all.size).to eq(0)
  end
end