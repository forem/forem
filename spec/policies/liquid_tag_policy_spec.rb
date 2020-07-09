require "rails_helper"

RSpec.describe LiquidTagPolicy, type: :policy do
  let(:liquid_tag) { instance_double(Liquid::Tag) }

  describe "initialize?" do
    let(:action) { :initialize? }
    let(:article) { create(:article) }

    it "raises an error if user is missing" do
      user = nil
      parse_context = { source: article, user: user }
      allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
      stub_const("#{liquid_tag.class}::VALID_ROLES", [:admin])
      expect do
        Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
      end.to raise_error(Pundit::NotAuthorizedError, "No user found")
    end

    it "authorizes and skips logic if liquid tag is not role restricted" do
      user = create(:user)
      parse_context = { source: article, user: user }
      allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
      allow(user).to receive(:has_role?)
      expect do
        Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
      end.not_to raise_error
      expect(user).not_to have_received(:has_role?)
    end

    it "authorizes if user has the correct role" do
      user = create(:user, :admin)
      parse_context = { source: article, user: user }

      allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
      stub_const("#{liquid_tag.class}::VALID_ROLES", [:admin])
      expect do
        Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
      end.not_to raise_error
    end

    it "handles single resource roles" do
      user = create(:user)
      # Stub roles because adding them normally can cause flaky specs
      single_resource_role = [:restricted_liquid_tag, LiquidTags::UserSubscriptionTag]
      allow(user).to receive(:has_role?).and_call_original
      allow(user).to receive(:has_role?).with(*single_resource_role).and_return(true)
      parse_context = { source: article, user: user }

      allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
      stub_const("#{liquid_tag.class}::VALID_ROLES", [single_resource_role])
      expect do
        Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
      end.not_to raise_error
    end

    it "raises error if user does not have the correct role" do
      user = create(:user)
      parse_context = { source: article, user: user }
      allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
      stub_const("#{liquid_tag.class}::VALID_ROLES", [:not_permitted])
      expect do
        Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
      end.to raise_error(Pundit::NotAuthorizedError, "User is not permitted to use this liquid tag")
    end
  end
end
