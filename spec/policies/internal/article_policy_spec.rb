require "rails_helper"

RSpec.describe Internal::ArticlePolicy do
  subject(:article_policy) { described_class }

  context "when regular user" do
    let(:user) { build(:user) }

    it { is_expected.to forbid_actions(%i[index]) }
  end
end
