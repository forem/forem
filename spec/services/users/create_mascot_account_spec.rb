require "rails_helper"

RSpec.describe Users::CreateMascotAccount, type: :service do
  it "defines MASCOT_PARMS" do
    expect(described_class.const_defined?(:MASCOT_PARAMS)).to be true
  end

  context "when a mascot user doesn't exist" do
    before { allow(SiteConfig).to receive(:mascot_user_id).and_return(nil) }

    it "creates a mascot account" do
      expect do
        described_class.call
      end.to change(User, :count).by(1)

      mascot_account = User.last
      expect(mascot_account.username).to eq Users::CreateMascotAccount::MASCOT_PARAMS[:username]
      expect(mascot_account.email).to eq Users::CreateMascotAccount::MASCOT_PARAMS[:email]
    end
  end

  context "when a mascot user already exists" do
    let(:mascot) { create(:user) }

    before do
      allow(User).to receive(:mascot_account).and_return(mascot)
      allow(User).to receive(:create)
    end

    it "does nothing" do
      described_class.call
      expect(User).not_to have_received(:create)
    end
  end
end
