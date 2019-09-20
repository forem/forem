require "rails_helper"

RSpec.describe Internal::BufferUpdatePolicy do
  subject { described_class.new(user, BufferUpdate) }

  let(:user) { build_stubbed(:user) }

  context "when regular user" do
    it { is_expected.to forbid_actions(%i[create update]) }
  end

  context "when user is permission to update buffers" do
    before { user.add_role(:single_resource_admin, BufferUpdate) }

    it { is_expected.to permit_actions(%i[create update]) }
  end

  context "when user is an admin" do
    before { user.add_role(:admin) }

    it { is_expected.to permit_actions(%i[create update]) }
  end

  context "when user is a super_admin" do
    before { user.add_role(:super_admin) }

    it { is_expected.to permit_actions(%i[create update]) }
  end
end
