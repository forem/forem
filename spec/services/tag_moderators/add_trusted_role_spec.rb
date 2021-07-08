require "rails_helper"

RSpec.describe TagModerators::AddTrustedRole, type: :service do
  let(:user) { create(:user) }

  it "adds the trusted role to a user" do
    expect { described_class.call(user) }.to change { user.reload.roles.size }.by(1)
  end

  it "does not add the fole for suspended users" do
    user = create(:user, :suspended)
    expect { described_class.call(user) }.not_to change { user.reload.roles.size }
  end

  it "signs the user up for the community mods newsletter" do
    expect do
      described_class.call(user)
    end.to change { user.reload.email_community_mod_newsletter }.from(false).to(true)
  end
end
