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

  describe ".on_user" do
    let(:user) { create(:user) }
    let(:admin) { create(:user) }

    it "finds logs where user is the explicit target (integer)" do
      log = create(:audit_log, user: admin, data: { "action" => "user_status", "target_user_id" => user.id })
      expect(described_class.on_user(user)).to include(log)
    end

    it "finds logs where user is the explicit target (string)" do
      log = create(:audit_log, user: admin, data: { "action" => "mark_as_spam", "target_user_id" => user.id.to_s })
      expect(described_class.on_user(user)).to include(log)
    end

    it "finds logs where user is the reactable target" do
      log = create(:audit_log, user: admin,
                               data: { "action" => "create", "controller" => "reactions",
                                       "reactable_type" => "User", "reactable_id" => user.id.to_s })
      expect(described_class.on_user(user)).to include(log)
    end

    it "does not match reactable_type User with a different reactable_id" do
      other_user = create(:user)
      log = create(:audit_log, user: admin,
                               data: { "action" => "create", "controller" => "reactions",
                                       "reactable_type" => "User", "reactable_id" => other_user.id.to_s })
      expect(described_class.on_user(user)).not_to include(log)
    end

    it "does not match reactable_id without reactable_type User" do
      log = create(:audit_log, user: admin,
                               data: { "action" => "create", "controller" => "reactions",
                                       "reactable_type" => "Article", "reactable_id" => user.id.to_s })
      expect(described_class.on_user(user)).not_to include(log)
    end

    it "does not include unrelated logs" do
      other_user = create(:user)
      log = create(:audit_log, user: other_user,
                               data: { "action" => "test", "target_user_id" => other_user.id })
      expect(described_class.on_user(user)).not_to include(log)
    end
  end
end
