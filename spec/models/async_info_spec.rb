require "rails_helper"

RSpec.describe AsyncInfo do
  describe "#to_hash_for" do
    subject(:async_info) { described_class.to_hash(user: user, context: context) }

    let(:user) { create(:user) }
    let(:feed_style_preference) { Settings::UserExperience.feed_style }
    let(:context) { AsyncInfoController.new }

    # Because of edge caching considerations, I'm short-circuiting that check.  For the applicable
    # controller, we should always have an authenticated user and it is not edge cached.
    before { allow(context).to receive(:current_user).and_return(user) }

    it "has a policies key with an array of policies" do
      policies = async_info.fetch(:policies)
      expect(policies.length).to be > 0

      # All policy keys will have dom_class and forbidden
      expect(policies.map(&:keys).uniq).to eq([%i[dom_class visible]])
    end
  end
end
