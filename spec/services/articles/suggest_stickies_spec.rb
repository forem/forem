require "rails_helper"

RSpec.describe Articles::SuggestStickies, type: :services do
  let(:article) { create(:article).decorate }

  describe ".call" do
    subject(:method_call) { described_class.call(article) }

    it { is_expected.to be_a Array }
  end
end
