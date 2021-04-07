require "rails_helper"

RSpec.describe ArticlePolicy do
  subject { described_class.new(user, article) }

  let!(:user) { create(:user) }

  let(:article) { build_stubbed(:article) }
  let(:valid_attributes) do
    %i[title body_html body_markdown main_image published
       description tag_list publish_under_org
       video video_code video_source_url video_thumbnail_url receive_notifications]
  end

  before { allow(article).to receive(:published).and_return(true) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is not the author" do
    it { is_expected.to permit_actions(%i[new create preview]) }
    it { is_expected.to forbid_actions(%i[update edit manage delete_confirm destroy admin_unpublish]) }

    context "with suspended status" do
      before { user.add_role(:suspended) }

      it { is_expected.to permit_actions(%i[new preview]) }
      it { is_expected.to forbid_actions(%i[create edit manage update delete_confirm destroy admin_unpublish]) }
    end
  end

  context "when user is the author" do
    let(:article) { build_stubbed(:article, user: user) }

    it { is_expected.to permit_actions(%i[update edit manage new create delete_confirm destroy preview]) }
    it { is_expected.to permit_mass_assignment_of(valid_attributes) }

    context "with suspended status" do
      before { user.add_role(:suspended) }

      it { is_expected.to permit_actions(%i[update new delete_confirm destroy preview]) }
    end
  end

  context "when user is a super_admin" do
    let(:user) { build(:user, :super_admin) }

    it { is_expected.to permit_actions(%i[update new edit manage create delete_confirm destroy preview]) }
    it { is_expected.to permit_actions(%i[admin_unpublish]) }
  end
end
