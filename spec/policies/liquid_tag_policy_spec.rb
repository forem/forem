require "rails_helper"

RSpec.describe LiquidTagPolicy, type: :policy do
  let(:liquid_tag) { instance_double(LiquidTagBase, user_authorization_method_name: user_authorization_method_name) }
  let(:article) { instance_double(Article) }
  let(:parse_context) { { source: article, user: user } }
  let(:user) { nil }
  let(:user_authorization_method_name) { nil }

  before do
    allow(liquid_tag).to receive(:user_authorization_method_name).and_return(user_authorization_method_name)
    allow(liquid_tag).to receive(:parse_context).and_return(parse_context)
  end

  describe "initialize?" do
    let(:action) { :initialize? }

    context "when parsing a non-restricted tag without a user" do
      let(:user_authorization_method_name) { nil }
      let(:user) { nil }

      it "authorizes" do
        expect do
          Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
        end.not_to raise_error
      end
    end

    context "when parsing a non-restricted tag with a user" do
      let(:user) { instance_double(User) }

      it "authorizes" do
        expect do
          Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
        end.not_to raise_error
      end
    end

    context "when parsing a restricted tag without a user" do
      let(:user_authorization_method_name) { :admin? }
      let(:user) { nil }

      it "does not authorize" do
        expect do
          Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
        end.to raise_error(Pundit::NotAuthorizedError, "No user found")
      end
    end

    context "when parsing a restricted tag with a user who **does not** meet the criteria" do
      let(:user_authorization_method_name) { :admin? }
      let(:user) { instance_double(User, user_authorization_method_name => false) }

      it "does not authorize" do
        expect do
          Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
        end.to raise_error(Pundit::NotAuthorizedError, "User is not permitted to use this liquid tag")
      end
    end

    context "when parsing a restricted tag with a user who meets the criteria" do
      let(:user_authorization_method_name) { :admin? }
      let(:user) { instance_double(User, user_authorization_method_name => true) }

      it "does not authorize" do
        expect do
          Pundit.authorize(user, liquid_tag, action, policy_class: described_class)
        end.not_to raise_error
      end
    end
  end
end
