require "rails_helper"

RSpec.describe Users::CreateMascotAccount, type: :service do
  it "defines MASCOT_PARMS" do
    expect(described_class.const_defined?(:MASCOT_PARAMS)).to be true
  end

  context "when a mascot user doesn't exist" do
    before { allow(Settings::General).to receive(:mascot_user_id).and_return(nil) }

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
    before do
      allow(Settings::General).to receive(:mascot_user_id).and_return(2)
      allow(User).to receive(:create)
    end

    it "raises an error" do
      expect { described_class.call }.to raise_error(StandardError)
    end
  end
end
