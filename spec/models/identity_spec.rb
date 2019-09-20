require "rails_helper"

RSpec.describe Identity, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:uid) }
  it { is_expected.to validate_presence_of(:provider) }
  it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }
  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:provider) }
  it { is_expected.to validate_inclusion_of(:provider).in_array(%w[github twitter]) }
  it { is_expected.to serialize(:auth_data_dump) }

  describe ".find_for_oauth" do
    it "works" do
      allow(described_class).to receive(:find_or_create_by)
      auth = { uid: 0, provider: "github" }
      described_class.find_for_oauth(instance_double("request", auth))
      expect(described_class).to have_received(:find_or_create_by).with(auth)
    end
  end
end
