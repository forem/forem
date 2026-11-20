require "rails_helper"

RSpec.describe Spam::BlockDomainAndSuspendUsersWorker, type: :worker do
  let!(:user) { create(:user, email: "spammer@spammy.example") }

  it "suspends users on the domain and records an audit log on each" do
    described_class.new.perform("spammy.example")

    expect(user.reload).to be_suspended
    expect(AuditLog.on_user(user).find_by(slug: "automatic_suspended").data)
      .to include("reason" => "email_domain", "domain" => "spammy.example")
  end

  it "does not auto-suspend users belonging to an organization with baseline_score > 0" do
    organization = create(:organization, baseline_score: 10)
    create(:organization_membership, user: user, organization: organization, type_of_user: "member")

    described_class.new.perform("spammy.example")

    expect(user.reload).not_to be_suspended
    expect(AuditLog.on_user(user).find_by(slug: "automatic_suspended")).to be_nil
  end
end
