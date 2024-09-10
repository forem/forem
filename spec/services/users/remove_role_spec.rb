require "rails_helper"

RSpec.describe Users::RemoveRole, type: :service do
  let(:current_user) { create(:user, :admin) }

  it "removes roles from users", :aggregate_failures do
    user = create(:user, :trusted)
    role = user.roles.first
    resource_type = nil
    args = { user: user, role: role, resource_type: resource_type }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  it "removes :single_resource_admin roles from users", :aggregate_failures do
    user = create(:user, :single_resource_admin)
    role = user.roles.first
    resource_type = "Comment"
    args = { user: user, role: role, resource_type: resource_type }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be true
    expect(role_removal.error_message).to be_nil
    expect(user.roles.count).to eq 1
  end

  context "when removing tag mod role" do
    let(:user) { create(:user) }
    let(:tag) { create(:tag, name: "ruby") }
    let(:go_tag) { create(:tag, name: "go") }

    before do
      user.add_role(:tag_moderator, tag)
      user.add_role(:tag_moderator, go_tag)
    end

    it "removes the role (with resource_id)" do
      expect(user.tag_moderator?(tag: tag)).to be true
      described_class.call(user: user, role: "tag_moderator", resource_type: "Tag", resource_id: tag.id)
      user.reload
      expect(user.tag_moderator?(tag: tag)).to be false
    end

    it "doesn't remove other tag mod role" do
      described_class.call(user: user, role: "tag_moderator", resource_type: "Tag", resource_id: go_tag.id)
      user.reload
      expect(user.tag_moderator?(tag: tag)).to be true
    end
  end

  it "returns an error if there is an issue removing the role" do
    user = create(:user)
    allow(user).to receive(:remove_role).and_raise(StandardError)
    args = { user: user, role: nil, resource_type: nil }
    role_removal = described_class.call(**args)

    expect(role_removal.success).to be false
  end

  # to update profile header cache
  it "touches users profile" do
    user = create(:user, :spam)
    profile = instance_double(Profile)
    allow(user).to receive(:profile).and_return(profile)
    allow(profile).to receive(:touch)
    described_class.call(user: user, role: :spam, resource_type: nil)
    expect(profile).to have_received(:touch)
  end
end
