# This cluster of shared examples all help facilitate bombarding policies with lots of test situations.
#
# There is an assumption that the :user (e.g. `let(:user)`) is the person whom we're authorizing.
RSpec.shared_examples "it requires an authenticated user" do
  let(:user) { nil }

  it "otherwise raises ApplicationPolicy::UserRequiredError" do
    expect { subject }.to raise_error(ApplicationPolicy::UserRequiredError)
  end
end

RSpec.shared_examples "it requires a user in good standing" do
  let(:user) { create(:user, :suspended) }

  it "otherwise raises ApplicationPolicy::UserSuspendedError" do
    expect { subject }.to raise_error(ApplicationPolicy::UserSuspendedError)
  end
end

RSpec.shared_examples "permitted roles" do |**kwargs|
  to = kwargs.delete(:to)
  label = kwargs.except(:to).map { |key, value| "#{key} is #{value}" }.join(" AND ")
  label = "when #{label} " if label.present?

  Array(to).each do |role|
    context "#{label}#{role.inspect} authorization" do
      before { kwargs.each { |k, v| allow(described_class).to receive(k).and_return(v) } }

      if role == :suspended_author
        let(:author) { suspended_user }
        let(:user) { author }
      else
        let(:user) { public_send(role) }
      end

      it { is_expected.to be_truthy }
    end
  end
end

RSpec.shared_examples "disallowed roles" do |**kwargs|
  to = kwargs.delete(:to)
  label = kwargs.map { |key, value| "#{key} is #{value}" }.join(" AND ")
  label = "when #{label} " if label.present?

  Array(to).each do |role|
    context "#{label}#{role.inspect} authorization" do
      before { kwargs.each { |k, v| allow(described_class).to receive(k).and_return(v) } }

      if role == :suspended_author
        let(:author) { suspended_user }
        let(:user) { author }
      else
        let(:user) { public_send(role) }
      end

      it { is_expected.to be_falsey }
    end
  end
end
