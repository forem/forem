require "rails_helper"

RSpec.describe Internal::CommentPolicy do
  subject { described_class.new(user, comment) }

  let(:comment) { Comment }
  let(:user) { build_stubbed(:user) }

  context "when regular user" do
    it { is_expected.to forbid_actions(%i[index]) }
  end

  context "when user has a scoped article admin role" do
    before { user.add_role(:single_resource_admin, Comment) }

    it { is_expected.to permit_actions(%i[index]) }
  end
end
