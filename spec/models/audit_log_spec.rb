require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it { is_expected.to belong_to(:user).optional }
end
