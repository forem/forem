require "rails_helper"

RSpec.describe Users::CreateMascotAccount, type: :service do
  it "defines static MASCOT_PARAMS without eager-evaluating dynamic settings at class load time" do
    expect(described_class.const_defined?(:MASCOT_PARAMS)).to be true
    expect(described_class::MASCOT_PARAMS.keys).to contain_exactly(:email, :username)
  end

  describe "#mascot_params" do
    it "lazily generates profile_image, timestamps, and matching password confirmation" do
      params = described_class.new.mascot_params

      expect(params[:email]).to eq(described_class::MASCOT_PARAMS[:email])
      expect(params[:username]).to eq(described_class::MASCOT_PARAMS[:username])
      expect(params[:profile_image]).to eq(Settings::General.mascot_image_url)
      expect(params[:confirmed_at]).to be_present
      expect(params[:registered_at]).to be_present
      expect(params[:password]).to be_present
      expect(params[:password_confirmation]).to eq(params[:password])
    end
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
