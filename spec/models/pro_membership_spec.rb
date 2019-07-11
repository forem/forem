require "rails_helper"

RSpec.describe ProMembership, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:user) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_presence_of(:expires_at).on(:save) }
  it { is_expected.to validate_inclusion_of(:status).in_array(ProMembership::STATUSES) }
  it { is_expected.to have_db_index(:status) }
  it { is_expected.to have_db_index(:expires_at) }

  describe "constants" do
    it "has the correct values for constants" do
      expect(Sponsorship::STATUSES).to eq(%w[active expired])
      expect(Sponsorship::MONTHLY_COST).to eq(5)
    end
  end

  describe "creation" do
    it "sets expires_at to a month from now" do
      Timecop.freeze(Time.current) do
        pm = ProMembership.create!(user: create(:user))
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

    it "makes the membership active" do
      Timecop.freeze(Time.current) do
        pro_membership.renew!
        expect(pro_membership.reload.active?).to be(true)
      end
    end
  end
end
