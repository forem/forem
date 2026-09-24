require "rails_helper"

RSpec.describe Articles::Feeds::EngagementCandidates, type: :service do
  subject(:feed) { described_class.call(exclude_author: user) }

  let(:user) { create(:user) }
  let(:minimum_score) { Settings::UserExperience.home_feed_minimum_score }

  it "includes high-quality, under-discussed published posts" do
    article = create(:article, published: true, score: minimum_score + 10)

    expect(feed).to include(article)
  end

  it "excludes posts below the minimum score" do
    low = create(:article, published: true, score: minimum_score - 1)

    expect(feed).not_to include(low)
  end

  it "excludes posts with more than 5 comments" do
    busy = create(:article, published: true, score: minimum_score + 10)
    busy.update_column(:comments_count, 6)

    expect(feed).not_to include(busy)
  end

  it "excludes unpublished posts" do
    draft = create(:article, published: false, score: minimum_score + 10)

    expect(feed).not_to include(draft)
  end

  it "excludes the posts of the user given as exclude_author" do
    own = create(:article, user: user, published: true, score: minimum_score + 10)

    expect(feed).not_to include(own)
  end

  it "orders by score, highest first" do
    lower = create(:article, published: true, score: minimum_score + 1)
    higher = create(:article, published: true, score: minimum_score + 100)

    expect(feed.to_a.index(higher)).to be < feed.to_a.index(lower)
  end
end
