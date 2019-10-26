require "rails_helper"

RSpec.describe AuditLog, type: :model do
  let(:user) { create(:user) }
  let(:audit_log) { create(:audit_log, user_id: user.id) }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:user_id) }
end
