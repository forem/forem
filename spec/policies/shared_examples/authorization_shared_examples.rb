# This cluster of shared examples all help facilitate bombarding policies with lots of test situations.
#
# There is an assumption that the :user (e.g. `let(:user)`) is the person whom we're authorizing.
RSpec.shared_examples "it requires an authenticated user" do
  let(:user) { nil }

  it "otherwise raises ApplicationPolicy::UserRequiredError", :aggregate_failures do
    Array(policy_method).each do |method_name|
      expect { policy.public_send(method_name) }.to raise_error(ApplicationPolicy::UserRequiredError)
    end
  end
end

RSpec.shared_examples "it requires a user in good standing" do
  let(:user) { defined?(suspended_user) ? suspended_user : create(:user, :without_profile, :suspended) }

  it "otherwise raises ApplicationPolicy::UserSuspendedError", :aggregate_failures do
    Array(policy_method).each do |method_name|
      expect { policy.public_send(method_name) }.to raise_error(ApplicationPolicy::UserSuspendedError)
    end
  end
end

RSpec.shared_examples "permitted roles" do |**kwargs|
  to = Array(kwargs.delete(:to))
  label = kwargs.map { |key, value| "#{key} is #{value}" }.join(" AND ")
  label = "when #{label} " if label.present?

  if to.any?
    context "with #{label}#{to.map(&:inspect).join(', ')} authorization" do
      let(:user) { to.first == :suspended_author ? suspended_user : public_send(to.first) }

      before { kwargs.each { |k, v| allow(described_class).to receive(k).and_return(v) } }

      it "permits #{to.map(&:inspect).join(', ')}", :aggregate_failures do
        to.each do |role|
          role_policy = policy_for_role(role)
          Array(policy_method).each do |method_name|
            expect(role_policy.public_send(method_name)).to be_truthy
          end
        end
      end
    end
  end
end

RSpec.shared_examples "disallowed roles" do |**kwargs|
  to = Array(kwargs.delete(:to))
  label = kwargs.map { |key, value| "#{key} is #{value}" }.join(" AND ")
  label = "when #{label} " if label.present?

  if to.any?
    context "with #{label}#{to.map(&:inspect).join(', ')} authorization" do
      let(:user) { to.first == :suspended_author ? suspended_user : public_send(to.first) }

      before { kwargs.each { |k, v| allow(described_class).to receive(k).and_return(v) } }

      it "disallows #{to.map(&:inspect).join(', ')}", :aggregate_failures do
        to.each do |role|
          role_policy = policy_for_role(role)
          Array(policy_method).each do |method_name|
            expect(role_policy.public_send(method_name)).to be_falsey
          end
        end
      end
    end
  end
end
