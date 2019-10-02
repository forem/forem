require "rails_helper"

RSpec.describe ProMembership, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_presence_of(:expires_at).on(:save) }
  it { is_expected.to validate_presence_of(:expiration_notifications_count) }
  it { is_expected.to validate_inclusion_of(:status).in_array(ProMembership::STATUSES) }
  it { is_expected.to have_db_index(:status) }
  it { is_expected.to have_db_index(:expires_at) }

  describe "constants" do
    it "has the correct values for constants" do
      expect(ProMembership::STATUSES).to eq(%w[active expired])
      expect(ProMembership::MONTHLY_COST).to eq(5)
      expect(ProMembership::MONTHLY_COST_USD).to eq(25)
    end
  end

  describe "defaults" do
    it "has the correct defaults" do
      pm = described_class.new
      expect(pm.status).to eq("active")
      expect(pm.expires_at).to be(nil)
      expect(pm.expiration_notification_at).to be(nil)
      expect(pm.expiration_notifications_count).to eq(0)
      expect(pm.auto_recharge).to be(false)
    end
  end

  describe "creation" do
    it "sets expires_at to a month from now" do
      Timecop.freeze(Time.current) do
        pm = described_class.create!(user: create(:user))
        expect(pm.expires_at.to_i).to eq(1.month.from_now.to_i)
      end
    end
  end

  describe "#expired?" do
    it "returns false if expires_at is in the future" do
      Timecop.freeze(Time.current) do
        pm = build(:pro_membership, expires_at: 5.seconds.from_now)
        expect(pm.expired?).to be(false)
      end
    end

    it "returns true if expires_at is in the past" do
      Timecop.freeze(Time.current) do
        pm = build(:pro_membership, expires_at: 5.seconds.ago)
        expect(pm.expired?).to be(true)
      end
    end
  end

  describe "#active?" do
    it "returns true if expires_at is in the future" do
      Timecop.freeze(Time.current) do
        pm = build(:pro_membership, expires_at: 5.seconds.from_now)
        expect(pm.active?).to be(true)
      end
    end

    it "returns false if expires_at is in the past" do
      Timecop.freeze(Time.current) do
        pm = build(:pro_membership, expires_at: 5.seconds.ago)
        expect(pm.active?).to be(false)
      end
    end
  end

  describe "#expire!" do
    let(:pro_membership) { create(:pro_membership) }

    it "sets expires_at to the current time" do
      Timecop.freeze(Time.current) do
        pro_membership.expire!
        expect(pro_membership.reload.expires_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "sets status to expired" do
      Timecop.freeze(Time.current) do
        pro_membership.expire!
        expect(pro_membership.reload.status).to eq("expired")
      end
    end

    it "makes the membership expired" do
      Timecop.freeze(Time.current) do
        pro_membership.expire!
        expect(pro_membership.reload.expired?).to be(true)
      end
    end
  end

  describe "#renew!" do
    let(:pro_membership) { create(:pro_membership) }

    it "sets expires_at to a month from now" do
      Timecop.freeze(Time.current) do
        pro_membership.renew!
        expect(pro_membership.reload.expires_at.to_i).to eq(1.month.from_now.to_i)
      end
    end

    it "sets status to active" do
      Timecop.freeze(Time.current) do
        pro_membership.renew!
        expect(pro_membership.reload.status).to eq("active")
      end
    end

    it "sets expiration_notification_at to nil" do
      Timecop.freeze(Time.current) do
        pro_membership.update_column(:expiration_notification_at, Time.current)
        pro_membership.renew!
        expect(pro_membership.reload.expiration_notification_at).to be(nil)
      end
    end

    it "sets expiration_notifications_count to 0" do
      Timecop.freeze(Time.current) do
        pro_membership.update_column(:expiration_notifications_count, 1)
        pro_membership.renew!
        expect(pro_membership.reload.expiration_notifications_count).to eq(0)
      end
    end

    it "makes the membership active" do
      Timecop.freeze(Time.current) do
        pro_membership.renew!
        expect(pro_membership.reload.active?).to be(true)
      end
    end
  end
end
