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
end
