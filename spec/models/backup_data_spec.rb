require "rails_helper"

RSpec.describe BackupData, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:instance_type) }
    it { is_expected.to validate_presence_of(:instance_id) }
    it { is_expected.to validate_presence_of(:json_data) }
    it { is_expected.to belong_to(:instance) }
    it { is_expected.to belong_to(:instance_user).class_name("User") }
  end
end
