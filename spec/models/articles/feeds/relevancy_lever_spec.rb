require "rails_helper"

RSpec.describe Articles::Feeds::RelevancyLever do
  subject do
    described_class.new(
      key: :my_key,
      label: "My label",
      select_fragment: "articles.reaction_count",
      user_required: true,
    )
  end

  it { is_expected.to respond_to :key }
  it { is_expected.to respond_to :label }
  it { is_expected.to respond_to :select_fragment }
  it { is_expected.to respond_to :joins_fragment }
  it { is_expected.to respond_to :group_by_fragment }
  it { is_expected.to respond_to :user_required }
  it { is_expected.to respond_to :user_required? }
end
