require "rails_helper"

RSpec.describe Articles::Feeds do
  describe ".lever_catalog" do
    subject { described_class.lever_catalog }

    it { is_expected.to be_a(Articles::Feeds::LeverCatalogBuilder) }
    it { is_expected.to be_frozen }
  end
end
