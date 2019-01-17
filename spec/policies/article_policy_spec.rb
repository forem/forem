require "rails_helper"

RSpec.describe ArticlePolicy do
  subject { described_class.new(user, article) }

  let(:article) { build(:article) }
  let(:valid_attributes) do
    %i[title body_html body_markdown user_id main_image published
       description allow_small_edits allow_big_edits tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url]
  end

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    let(:user) { build(:user) }

    it { is_expected.to permit_actions(%i[new create preview]) }
    it { is_expected.to forbid_actions(%i[update delete_confirm destroy analytics_index toggle_mute]) }

    context "with banned status" do
      before { user.add_role :banned }

      it { is_expected.to permit_actions(%i[new preview]) }
      it { is_expected.to forbid_actions(%i[create update delete_confirm destroy analytics_index toggle_mute]) }
    end
  end

  context "when user is the author" do
    let(:user) { article.user }

    it { is_expected.to permit_actions(%i[update new create delete_confirm destroy preview toggle_mute]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }

    context "with banned status" do
      before { user.add_role :banned }

      it { is_expected.to permit_actions(%i[update new delete_confirm destroy preview toggle_mute]) }
    end
  end

  context "when user is a super_admin" do
    let(:user) { build(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[update new create delete_confirm destroy preview]) }
  end

  context "when user does not have any analytics permission" do
    let(:user) { build(:user) }

    it { is_expected.to forbid_action(:analytics_index) }
  end

  context "when trying to view analytics with proper permissions" do
    let(:org_admin)         { build(:user, :org_admin) }
    let(:super_admin)       { build(:user, :super_admin) }
    let(:analytics_user)    { build(:user, :analytics, organization_id: org_admin.organization_id) }
    let(:article) do
      build(:article, user_id: analytics_user.id, organization_id: org_admin.organization_id)
    end

    it "allows all users to view analytics" do
      described_classes = [org_admin, super_admin, analytics_user].map do |user|
        described_class.new(user, article)
      end
      expect(described_classes).to all(permit_action(:analytics_index))
    end
  end

  context "when a user with analytics tries to view someone else's article" do
    let(:user)          { create(:user, :analytics) }
    let(:other_user)    { create(:user, :analytics) }
    let(:article)       { create(:article, user_id: user.id) }
    let(:article2)      { create(:article, user_id: other_user.id) }

    it "forbids the first user from viewing the other user's analytics via their article" do
      expect(described_class.new(user, article2)).to forbid_action(:analytics_index)
    end

    it "forbids the other user from viewing the first user's analytics" do
      expect(described_class.new(other_user, article)).to forbid_action(:analytics_index)
    end

    it "forbids them from viewing another person's analytics even if their article is first" do
      articles = Article.all
      expect(described_class.new(user, articles)).to forbid_action(:analytics_index)
    end
  end
end
