require "rails_helper"

RSpec.describe TagModerators::Remove, type: :service do
  let(:user) { create(:user) }
  let(:tag) { create(:tag) }

  it "removes the tag_moderator role from the user" do
    user.add_role(:tag_moderator, tag)
    expect do
      described_class.call(user, tag)
    end.to change { user.reload.roles.count }.by(-1)
  end
end
