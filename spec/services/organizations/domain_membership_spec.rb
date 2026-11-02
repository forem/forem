require "rails_helper"

RSpec.describe Organizations::DomainMembership do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let!(:domain) { create(:organization_email_domain, :available, organization: organization) }
  let(:service) { described_class.new(user: user, organization: organization) }

  before { allow(ForemInstance).to receive(:smtp_enabled?).and_return(true) }

  def request_code(email = "employee@foobar.com")
    allow(SecureRandom).to receive(:random_number).and_call_original
    allow(SecureRandom).to receive(:random_number).with(100_000_000).and_return(12_345_678)
    service.request_code(email)
  end

  it "verifies a private work email without changing account credentials" do
    original_email = user.email
    challenge = request_code(" Employee@FooBar.com ")
    expect(challenge.email).to eq("employee@foobar.com")
    expect(challenge.otp_digest).not_to include("12345678")
    expect(ActionMailer::Base.deliveries.last.to).to eq(["employee@foobar.com"])
    expect(ActionMailer::Base.deliveries.last.body.encoded).to include("12345678")
    membership = service.verify(challenge.id, "12345678")
    expect(membership.type_of_user).to eq("member")
    expect(challenge.reload.consumed_at).to be_present
    expect(user.reload.email).to eq(original_email)
    expect(user.sign_in_token).to be_nil
  end

  it "does not accept a subdomain, suffix trick, or a malformed mailbox" do
    addresses = %w[employee@sub.foobar.com employee@evilfoobar.com employee@foobar.com.evil.com employee@@foobar.com]
    addresses.each do |email|
      expect { request_code(email) }.to raise_error(described_class::Error)
    end
  end

  it "invalidates the challenge when delivery fails" do
    allow(ForemInstance).to receive(:smtp_enabled?).and_return(false)
    expect { request_code }.to raise_error(described_class::Error, "delivery_failed")
    expect(OrganizationMembershipChallenge.last.expires_at).to be <= Time.current
  end

  it "does not send mail for a pending domain" do
    domain.update!(status: "pending")
    expect { request_code }.to raise_error(described_class::Error, "ineligible_domain")
    expect(OrganizationMembershipChallenge.count).to eq(0)
  end

  it "does not send mail for a disabled domain" do
    domain.update!(enabled: false)
    expect { request_code }.to raise_error(described_class::Error, "ineligible_domain")
  end

  it "persists failed guesses and locks the code after five failures" do
    challenge = request_code
    5.times do
      expect { service.verify(challenge.id, "00000000") }.to raise_error(described_class::Error, "invalid_code")
    end
    expect(challenge.reload.attempts).to eq(5)
    expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
    expect(organization.organization_memberships.count).to eq(0)
  end

  it "rejects an expired code" do
    challenge = request_code
    Timecop.travel(11.minutes.from_now) do
      expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
    end
  end

  it "prevents replay and duplicate membership" do
    challenge = request_code
    service.verify(challenge.id, "12345678")
    expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "already_member")
    expect(organization.organization_memberships.count).to eq(1)
  end

  it "does not accept another account's challenge" do
    challenge = request_code
    other_service = described_class.new(user: create(:user), organization: organization)
    expect { other_service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
  end

  it "does not accept a challenge for another organization" do
    challenge = request_code
    other_service = described_class.new(user: user, organization: create(:organization))
    expect { other_service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
  end

  it "invalidates outstanding codes when a superadmin revokes approval" do
    challenge = request_code
    domain.review!(create(:user, :super_admin), "revoked")
    expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
    expect(challenge.reload.expires_at).to be <= Time.current
  end

  it "converts a pending invitation into an ordinary membership" do
    pending = create(:organization_membership, user: user, organization: organization, type_of_user: "pending")
    challenge = request_code
    expect { service.verify(challenge.id, "12345678") }.not_to change(OrganizationMembership, :count)
    expect(pending.reload.type_of_user).to eq("member")
  end

  it "preserves existing admin access" do
    challenge = request_code
    membership = create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
    expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "already_member")
    expect(membership.reload.type_of_user).to eq("admin")
  end

  it "does not let a removed member immediately join again" do
    challenge = request_code
    membership = service.verify(challenge.id, "12345678")
    membership.delete
    expect { request_code }.to raise_error(described_class::Error, "invite_required")
  end

  it "requires an invitation after removal of a manually added member" do
    membership = create(:organization_membership, user: user, organization: organization)
    membership.destroy!
    expect { request_code }.to raise_error(described_class::Error, "invite_required")
  end

  it "cleans up private verification records when the member deletes their account" do
    challenge = request_code
    service.verify(challenge.id, "12345678")
    user.destroy!
    expect(OrganizationMembershipChallenge.exists?(challenge.id)).to be(false)
  end

  it "limits repeated sends even across organizations" do
    request_code
    expect { request_code }.to raise_error(described_class::Error, "rate_limited")
  end

  it "invalidates old codes on resend" do
    challenge = request_code
    Timecop.travel(2.minutes.from_now) do
      replacement = request_code
      expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "invalid_code")
      expect(service.verify(replacement.id, "12345678")).to be_persisted
    end
  end

  it "does not let one mailbox verify two accounts" do
    challenge = request_code
    service.verify(challenge.id, "12345678")
    other_service = described_class.new(user: create(:user), organization: organization)
    other_challenge = other_service.request_code("employee@foobar.com")
    expect { other_service.verify(other_challenge.id, "12345678") }
      .to raise_error(described_class::Error, "email_in_use")
  end

  it "checks suspension again at verification" do
    challenge = request_code
    user.add_role(:suspended)
    expect { service.verify(challenge.id, "12345678") }.to raise_error(described_class::Error, "unavailable")
  end
end
