require "rails_helper"

RSpec.describe "Article Organization Baseline Score", type: :model do
  let(:organization) { create(:organization, baseline_score: 10) }
  let(:user) { create(:user) }
  let(:article) { create(:article, user: user, organization: organization) }

  it "adds the organization baseline score to the article score" do
    # Initial score calculation should include the baseline
    article.update_score
    
    # We need to isolate the baseline score effect.
    # Let's calculate what the score would be without the organization.
    
    article_without_org = create(:article, user: user, organization: nil)
    article_without_org.update_score
    base_score = article_without_org.score

    # The difference should be the baseline score
    # Note: There might be slight differences if other factors like spam/featured/etc apply, 
    # but with fresh factories they should be identical except for the org.
    # However, let's just check if the baseline score is component of the total.
    
    # To be more precise, let's update the organization baseline and see the score change.
    initial_score = article.score
    
    organization.update(baseline_score: 50)
    article.update_score
    expect(article.score).to eq(initial_score + 40) # 50 - 10 = 40 increase
  end

  it "defaults to 0 if organization has no baseline score" do
    organization.update(baseline_score: nil)
    article.update_score
    score_with_nil = article.score

    organization.update(baseline_score: 0)
    article.update_score
    score_with_zero = article.score

    expect(score_with_nil).to eq(score_with_zero)
  end

  it "does not affect articles without an organization" do
    article_no_org = create(:article, user: user, organization: nil)
    initial_score = article_no_org.score
    
    article_no_org.update_score
    expect(article_no_org.score).to eq(initial_score)
  end
end
