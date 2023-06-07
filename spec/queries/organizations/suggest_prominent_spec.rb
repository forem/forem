require "rails_helper"

RSpec.describe Organizations::SuggestProminent, type: :service do
  subject(:suggester) { described_class.new(current_user) }

  let(:current_user) { create(:user) }
  let(:top_organizations) { create_list(:organization, 4) }
  let(:bad_organizations) { create_list(:organization, 2) }
  let(:mid_included) { create(:organization) }
  let(:mid_excluded) { create(:organization) }

  before do
    top_organizations.each do |organization|
      create_list(:article, 3, organization_id: organization.id, score: 15)
    end

    bad_organizations.each do |organization|
      create(:article, organization_id: organization.id, score: 1)
    end

    create(:article, organization_id: mid_included.id, score: 15)
    create(:article, organization_id: mid_excluded.id, score: 14)
  end

  context "when user is following any tags" do
    let(:followed) { create(:tag) }
    let(:unfollowed) { create(:tag) }
    let(:suggest_this_org) { create(:organization) }
    let(:dont_suggest_this) { create(:organization) }

    before do
      current_user.follow(followed)
      create_list(:article, 3, organization_id: suggest_this_org.id, score: 25, tags: followed.name)
      create(:article, organization_id: dont_suggest_this.id, score: 15, tags: unfollowed.name)
    end

    it "returns organizations with posts with at least an average score under followed tags" do
      results = suggester.suggest
      expect(results).not_to be_blank
      expect(results).to include(suggest_this_org)
      expect(results).not_to include(dont_suggest_this)
      expect(results).not_to include(bad_organizations.first)
      expect(results).not_to include(bad_organizations.last)
    end
  end

  it "returns max 5 organizations with posts with at least an average score under any tags" do
    results = suggester.suggest
    expect(results.size).to eq(5)
    expect(results).to include(*top_organizations)
    expect(results).to include(mid_included)
    expect(results).not_to include(mid_excluded)
    expect(results).not_to include(bad_organizations.first)
    expect(results).not_to include(bad_organizations.last)
  end

  it "does not include orgs with posts published more than 3 weeks ago" do
    old_timer = nil # so this is still accessible after block

    Timecop.travel(5.weeks.ago) do
      old_timer = create(:organization)
      create(:article, organization_id: old_timer.id, score: 50)
    end

    results = suggester.suggest
    expect(results).not_to include(old_timer)
  end
end
