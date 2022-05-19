require "rails_helper"

RSpec.describe Articles::Feeds::OrderByLever do
  subject do
    described_class.new(
      key: :my_key,
      label: "My label",
      order_by_fragment: "articles.reaction_count DESC",
    )
  end

  it { is_expected.to respond_to :key }
  it { is_expected.to respond_to :label }
  it { is_expected.to respond_to :order_by_fragment }
  it { is_expected.to respond_to :to_sql }
end
