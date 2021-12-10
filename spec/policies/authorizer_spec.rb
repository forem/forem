require "rails_helper"

# rubocop:disable RSpec/PredicateMatcher
RSpec.describe Authorizer, type: :policy do
  subject(:authorizer) { described_class.for(user: user) }

  let(:user) { create(:user) }

  it "delegates private #has_role? to user#__has_role_without_warning?" do
    allow(user).to receive(:__has_role_without_warning?).and_call_original
    authorizer.admin?
    expect(user).to have_received(:__has_role_without_warning?)
  end

  it "delegates private #has_any_role? to user#__has_any_role_without_warning?" do
    allow(user).to receive(:__has_any_role_without_warning?).and_call_original
    authorizer.workshop_eligible?
    expect(user).to have_received(:__has_any_role_without_warning?)
  end

  describe "#any_admin?" do
    # This test che
    it "queries the user's roles" do
      # I want to test `expect(authorizer.admin?)` but our rubocop
      # version squaks.
      expect(authorizer.admin?).to be_falsey
    end
  end

  describe "#administrative_access_to?" do
    context "when not an admin or super admin and not given a resource" do
      let(:user) { build(:user) }

      it "is false" do
        expect(authorizer.administrative_access_to?(resource: nil)).to be_falsey
      end
    end

    context "when an admin and not given a resource" do
      let(:user) { build(:user, :admin) }

      it "is false" do
        expect(authorizer.administrative_access_to?(resource: nil)).to be_truthy
      end
    end

    context "when a super_admin and not given a resource" do
      let(:user) { build(:user, :super_admin) }

      it "is false" do
        expect(authorizer.administrative_access_to?(resource: nil)).to be_truthy
      end
    end

    context "when given a resource and the user is assigned singular administration" do
      before do
        user.add_role(:single_resource_admin, Article)
      end

      it "is true" do
        expect(authorizer.administrative_access_to?(resource: Article)).to be_truthy
      end
    end

    context "when given a resource and the user is assigned singular administration to another" do
      before do
        user.add_role(:single_resource_admin, Article)
      end

      it "is true" do
        expect(authorizer.administrative_access_to?(resource: Comment)).to be_falsey
      end
    end
  end

  describe "#trusted?" do
    # We don't need a saved user.  Let's not require that.
    let(:user) { instance_double(User, id: 123) }

    it "memoizes the result from rolify" do
      allow(Rails.cache)
        .to receive(:fetch)
        .with("user-#{user.id}/has_trusted_role", expires_in: 200.hours)
        .and_return(false)
        .once

      2.times { authorizer.trusted? }
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
