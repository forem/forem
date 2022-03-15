require "rails_helper"

RSpec.describe ApplicationPolicy do
  # rubocop:disable RSpec/DescribedClass
  #
  # [@jeremyf] Disabling this because I'm testing inner classes, and explicit "This is the class"
  #            seems like a legible approach.
  describe ApplicationPolicy::NotAuthorizedError do
    subject(:error) { ApplicationPolicy::NotAuthorizedError.new("Message") }

    it { is_expected.to be_a(Pundit::NotAuthorizedError) }
    it { is_expected.to be_a(ApplicationPolicy::NotAuthorizedError) }
  end

  describe ApplicationPolicy::UserSuspendedError do
    subject(:error) { ApplicationPolicy::UserSuspendedError.new("Message") }

    it { is_expected.to be_a(Pundit::NotAuthorizedError) }
    it { is_expected.to be_a(ApplicationPolicy::NotAuthorizedError) }
  end

  describe ApplicationPolicy::UserRequiredError do
    subject(:error) { ApplicationPolicy::UserRequiredError.new("Message") }

    it { is_expected.to be_a(Pundit::NotAuthorizedError) }
    it { is_expected.to be_a(ApplicationPolicy::NotAuthorizedError) }
  end
  # rubocop:enable RSpec/DescribedClass

  describe "require_user_in_good_standing!" do
    subject(:method_call) { described_class.require_user_in_good_standing!(user: user) }

    context "when no user given" do
      let(:user) { nil }

      it { within_block_is_expected.to raise_error ApplicationPolicy::UserRequiredError }
    end

    context "when given a user who is not suspended" do
      let(:user) { User.new }

      it { is_expected.to be_truthy }
    end

    context "when given a user who suspended" do
      let(:user) { build(:user, :suspended) }

      it { within_block_is_expected.to raise_error ApplicationPolicy::UserSuspendedError }
    end
  end

  describe "require_user!" do
    subject(:method_call) { described_class.require_user!(user: user) }

    context "when no user given" do
      let(:user) { nil }

      it { within_block_is_expected.to raise_error ApplicationPolicy::UserRequiredError }
    end

    context "when given a user" do
      let(:user) { User.new }

      it { is_expected.to be_truthy }
    end
  end
end
