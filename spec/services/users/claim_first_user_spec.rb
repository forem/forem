require "rails_helper"

RSpec.describe Users::ClaimFirstUser, type: :service do
  def stored_setting_rows
    Settings::General.unscoped.where(var: "waiting_on_first_user")
  end

  def expect_first_user_roles(user)
    expect(user).to be_creator
    expect(user).to be_super_admin
    expect(user).to be_trusted
  end

  def expect_no_first_user_roles(user)
    expect(user).not_to be_creator
    expect(user).not_to be_super_admin
    expect(user).not_to be_trusted
  end

  context "when the setting is not stored" do
    it "grants the roles to the earliest user and records the claim", :aggregate_failures do
      expect(stored_setting_rows).not_to exist
      user = create(:user)

      expect(described_class.call(user)).to be true

      expect_first_user_roles(User.find(user.id))
      expect(stored_setting_rows.map(&:value)).to all(be false)
      expect(stored_setting_rows).to exist
    end

    it "does not grant the roles when an earlier user exists", :aggregate_failures do
      create(:user)
      user = create(:user)

      expect(described_class.call(user)).to be false

      expect_no_first_user_roles(User.find(user.id))
      expect(stored_setting_rows).not_to exist
    end
  end

  context "when the setting is stored as true" do
    before { Settings::General.unscoped.create!(var: "waiting_on_first_user", value: true) }

    it "grants the roles to the first claimant only", :aggregate_failures do
      first = create(:user)
      second = create(:user)

      expect(described_class.call(first)).to be true
      expect(described_class.call(second)).to be false

      expect_first_user_roles(User.find(first.id))
      expect_no_first_user_roles(User.find(second.id))
      expect(stored_setting_rows.map(&:value)).to all(be false)
    end
  end

  context "when the claim was already recorded" do
    it "does not grant the roles even to the earliest user" do
      Settings::General.unscoped.create!(var: "waiting_on_first_user", value: false)
      user = create(:user)

      expect(described_class.call(user)).to be false
      expect_no_first_user_roles(User.find(user.id))
    end
  end

  it "does not consume the claim when the surrounding transaction rolls back", :aggregate_failures do
    user = create(:user)

    ActiveRecord::Base.transaction(requires_new: true) do
      described_class.call(user)
      raise ActiveRecord::Rollback
    end

    expect_no_first_user_roles(User.find(user.id))
    expect(stored_setting_rows).not_to exist
    expect(described_class.call(user)).to be true
  end

  it "creates the mascot account only for the claiming user", :aggregate_failures do
    first = create(:user)
    expect(described_class.call(first)).to be true
    mascot_id = Settings::General.mascot_user_id
    expect(User.find(mascot_id)).to eq(User.mascot_account)

    second = create(:user)
    expect { described_class.call(second) }.not_to change(User, :count)
    expect(Settings::General.mascot_user_id).to eq(mascot_id)
  end

  it "does not consume the claim when the mascot account cannot be created", :aggregate_failures do
    user = create(:user)
    allow(Users::CreateMascotAccount).to receive(:call).and_raise(ActiveRecord::RecordInvalid)

    expect { described_class.call(user) }.to raise_error(ActiveRecord::RecordInvalid)

    expect_no_first_user_roles(User.find(user.id))
    expect(stored_setting_rows).not_to exist
  end

  it "does not keep cached claim settings after the surrounding transaction rolls back", :aggregate_failures do
    allow(Settings::General).to receive(:waiting_on_first_user).and_call_original
    Settings::General.unscoped.create!(var: "waiting_on_first_user", value: true)
    user = create(:user)

    ActiveRecord::Base.transaction(requires_new: true) do
      described_class.call(user)
      # A read inside the transaction caches the uncommitted values.
      expect(Settings::General.waiting_on_first_user).to be false
      expect(Settings::General.mascot_user_id).to be_present
      raise ActiveRecord::Rollback
    end

    expect(Settings::General.waiting_on_first_user).to be true
    expect(Settings::General.mascot_user_id).to be_nil

    expect(described_class.call(User.find(user.id))).to be true
    expect_first_user_roles(User.find(user.id))
  end

  it "serializes claimants with a transaction-level advisory lock" do
    allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original
    described_class.call(create(:user))

    expect(ActiveRecord::Base.connection).to have_received(:execute)
      .with("SELECT pg_advisory_xact_lock(#{described_class::LOCK_KEY})")
  end

  it "does nothing for an unsaved user" do
    expect(described_class.call(build(:user))).to be false
  end
end
