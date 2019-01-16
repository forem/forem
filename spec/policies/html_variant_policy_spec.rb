require "rails_helper"

RSpec.describe HtmlVariantPolicy do
  subject { described_class.new(user, html_variant) }

  context "when user is not an admin" do
    let(:user) { build(:user) }
    let(:html_variant) { build(:html_variant) }

    it { is_expected.to forbid_actions(%i[index show edit update create]) }
  end

  context "when user is an admin" do
    let(:user) { build(:user, :super_admin) }
    let(:html_variant) { build(:html_variant) }

    it { is_expected.to permit_actions(%i[index show edit update create]) }
  end
end
