require "rails_helper"

RSpec.describe Authentication::Authenticator, type: :service do
  let(:current_user) { create(:user) }

  def mlh_payload(uid:, email:)
    OmniAuth::AuthHash.new(
      provider: "mlh",
      uid: uid,
      info: OmniAuth::AuthHash::InfoHash.new(email: email, name: "MLH User"),
      credentials: OmniAuth::AuthHash.new(token: "tok_#{uid}", secret: "sec"),
      extra: { raw_info: { created_at: 2.years.ago.iso8601 } },
    )
  end

  before do
    omniauth_mock_mlh_payload
    allow(ForemStatsClient).to receive(:increment)
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

  context "when a different user is signed in and the incoming identity resolves elsewhere" do
    it "raises AccountSwitchConfirmation carrying the resolved target (exact verified email)" do
      target = create(:user)
      payload = mlh_payload(uid: "core-switch-1", email: target.email)

      expect do
        expect do
          described_class.call(payload, current_user: current_user)
        end.to raise_error(
          Authentication::Errors::AccountSwitchConfirmation,
        ) { |error| expect(error.target_user).to eq(target) }
      end.not_to change(Identity, :count)

    end
    it "raises AccountSwitchConfirmation carrying the resolved target (uid ownership)" do
      target = create(:user)
      create(:identity, user: target, provider: "mlh", uid: "core-switch-2")
      payload = mlh_payload(uid: "core-switch-2", email: "nobody-else@example.com")

      expect do
        described_class.call(payload, current_user: current_user)
      end.to raise_error(
        Authentication::Errors::AccountSwitchConfirmation,
      ) { |error| expect(error.target_user).to eq(target) }
    end

    it "fails closed without attaching when the resolved account is suspended" do
      target = create(:user)
      target.add_role(:suspended)
      payload = mlh_payload(uid: "core-switch-3", email: target.email)

      expect do
        expect do
          described_class.call(payload, current_user: current_user)
        end.to raise_error(Authentication::Errors::Ineligible)
      end.not_to change(Identity, :count)

      expect(current_user.reload.identities.where(provider: "mlh")).to be_none
      expect(target.reload.identities.where(provider: "mlh")).to be_none
    end
  end

  context "when the signed-in user resolves as the identity's owner themselves" do
    it "attaches normally without requiring confirmation" do
      payload = mlh_payload(uid: "core-self-1", email: current_user.email)

      expect(described_class.call(payload, current_user: current_user)).to eq(current_user)
      expect(current_user.identities.find_by(provider: "mlh").uid).to eq("core-self-1")
    end
  end

  context "when the incoming unclaimed identity resolves to nobody" do
    it "keeps the normal attach-to-current-user flow" do
      payload = mlh_payload(uid: "core-nobody-1", email: "unclaimed@example.com")

      expect do
        expect(described_class.call(payload, current_user: current_user)).to eq(current_user)
      end.to change(Identity, :count).by(1)
    end
  end

  context "when no user is signed in" do
    it "still links an eligible exact-email match without confirmation" do
      target = create(:user)
      payload = mlh_payload(uid: "core-link-1", email: target.email)

      expect(described_class.call(payload)).to eq(target)
      expect(target.identities.find_by(provider: "mlh").uid).to eq("core-link-1")
    end
  end
end
