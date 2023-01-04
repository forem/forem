require "rails_helper"

RSpec.describe AuditLog do
  let(:audit_log) { create(:audit_log) }

  describe "validations" do
    describe "builtin validations" do
      subject { audit_log }

      it { is_expected.to belong_to(:user).optional }

      it { is_expected.to validate_presence_of(:data) }
    end
  end
end
