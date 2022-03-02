require "rails_helper"

# These are methods that I envision extracting.  However, they are relevant only for these tests.
# And to extract would require more explict interface definition.
RSpec.shared_examples "it requires an authenticated user" do
  let(:user) { nil }
  specify "otherwise it raises ApplicationPolicy::UserRequiredError" do
    expect { subject }.to raise_error(ApplicationPolicy::UserRequiredError)
  end
end

RSpec.shared_examples "it requires a user in good standing" do
  let(:author) { create(:user, :suspended) }
  specify "otherwise it raises ApplicationPolicy::UserSuspendedError" do
    expect { subject }.to raise_error(ApplicationPolicy::UserSuspendedError)
  end
end

RSpec.shared_examples "permitted roles" do |kwargs|
  Array(kwargs.fetch(:to)).each do |role|
    context "#{role.inspect} authorization" do
      case role
      when :suspended_author
        let(:author) { create(:user, :suspended) }
      when :org_admin
        let(:organization) { user.organizations.first }
        let(:user) { create(:user, role, :org_admin) }
      when :anyone
        let(:user) { create(:user) }
      else
        let(:user) { create(:user, role) }
      end
      it { is_expected.to be_truthy }
    end
  end
end
RSpec.shared_examples "disallowed roles" do |kwargs|
  Array(kwargs.fetch(:to)).each do |role|
    context "#{role.inspect} authorization" do
      case role
      when :org_admin
        let(:organization) { user.organizations.first }
        let(:user) { create(:user, role, :org_admin) }
      when :author
        let(:user) { author }
      when :other_users
        let(:user) { create(:user) }
      else
        let(:user) { create(:user, role) }
      end
      it { is_expected.to be_falsey }
    end
  end
end

RSpec.shared_examples "it is otherwise unavailable" do
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  it { is_expected.to be_falsey }
end

RSpec.shared_examples "when limit_post_creation_to_admins is enabled" do |kwargs|
  before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

  Array(kwargs.fetch(:authorizes)).each do |role|
    context "when user is #{role.inspect}" do
      let(:user) { create(:user, role) }

      it { is_expected.to be_truthy }
    end
  end

  context "with the \"default\" user" do
    it { is_expected.to be_falsey }
  end
end

RSpec.describe ArticlePolicy do
  subject(:method_call) { policy.public_send(policy_method) }

  let(:author) { create(:user) }
  let(:organization) { nil }
  let(:user) { author }
  let(:resource) { build(:article, user: author, organization: organization) }
  let(:policy) { described_class.new(user, resource) }

  describe ".scope_users_authorized_to_action" do
    let!(:regular_user) { create(:user) }
    let!(:super_admin_user) { create(:user, :super_admin) }

    before { create(:user, :suspended) }

    context "when limit_post_creation_to_admins is true" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(true) }

      it "omits suspended and regular users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to match_array([super_admin_user])
      end
    end

    context "when limit_post_creation_to_admins is false" do
      before { allow(described_class).to receive(:limit_post_creation_to_admins?).and_return(false) }

      it "omits only suspended users" do
        results = described_class.scope_users_authorized_to_action(users_scope: User, action: :create?).to_a
        expect(results).to match_array([regular_user, super_admin_user])
      end
    end
  end

  describe "#feed?" do
    let(:policy_method) { :feed? }

    it { is_expected.to be_truthy }
  end

  %i[create? new? preview?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "it requires a user in good standing"
      it_behaves_like "permitted roles", to: [:anyone]
      it_behaves_like "when limit_post_creation_to_admins is enabled", authorizes: %i[super_admin admin]
    end
  end

  %i[update? edit?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "it requires a user in good standing"
      it_behaves_like "permitted roles", to: %i[super_admin admin org_admin]
      it_behaves_like "disallowed roles", to: [:other_users]
    end
  end

  describe "#stats?" do
    let(:policy_method) { :stats? }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin org_admin suspended_author]
    it_behaves_like "disallowed roles", to: %i[admin other_users]
  end

  describe "subscriptions?" do
    let(:policy_method) { :subscriptions? }

    it_behaves_like "it requires an authenticated user"
    it_behaves_like "permitted roles", to: %i[super_admin suspended_author]
    it_behaves_like "disallowed roles", to: %i[admin org_admin other_users]
  end

  %i[admin_unpublish? admin_featured_toggle?].each do |method_name|
    describe "admin_unpublish?" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin]
      it_behaves_like "disallowed roles", to: %i[org_admin author other_users]
    end
  end

  %i[destroy? delete_confirm? discussion_lock_confirm? discussion_unlock_confirm?].each do |method_name|
    describe "##{method_name}" do
      let(:policy_method) { method_name }

      it_behaves_like "it requires an authenticated user"
      it_behaves_like "permitted roles", to: %i[super_admin admin org_admin suspended_author]
      it_behaves_like "disallowed roles", to: [:other_users]
    end
  end
end
