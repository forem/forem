require "rails_helper"

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
    it "queries the user's roles" do
      # I want to test `expect(authorizer.admin?)` but our rubocop
      # version squaks.
      expect(authorizer).not_to be_any_admin
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
