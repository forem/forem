require "rails_helper"

RSpec.describe Spam::BlockDomainAndSuspendUsersWorker, type: :worker do
  let!(:user) { create(:user, email: "spammer@spammy.example") }

  it "suspends users on the domain and records an audit log on each" do
    described_class.new.perform("spammy.example")

    expect(user.reload).to be_suspended
    expect(AuditLog.on_user(user).find_by(slug: "automatic_suspended").data)
      .to include("reason" => "email_domain", "domain" => "spammy.example")
  end
end
