require "rails_helper"

# See ./spec/policies/shared_examples/authorization_shared_examples.rb for the various shared examples.
RSpec.describe SpacePolicy do
  subject(:method_call) { policy.public_send(policy_method) }

  let(:organization) { org_admin&.organizations&.first }

  # The named "folks" with one or more roles
  let(:org_admin) { create(:user, :org_admin) }
  let(:anyone) { create(:user) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:suspended_user) { create(:user, :suspended) }
  let(:admin) { create(:user, :admin) }
  let(:trusted) { create(:user, :trusted) }
  let(:other_users) { create(:user) }
  let(:author) { create(:user) }
  let(:resource) { Space.new }
  let(:policy) { described_class.new(user, resource) }

  %i[update? index?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin]
    end
  end
end
