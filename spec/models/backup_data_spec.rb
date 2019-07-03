require "rails_helper"

RSpec.describe BackupData, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:instance_type, :instance_id, :json_data) }
  end
end
