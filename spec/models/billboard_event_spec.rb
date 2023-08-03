require "rails_helper"

RSpec.describe BillboardEvent do
  it { is_expected.to validate_inclusion_of(:category).in_array(described_class::VALID_CATEGORIES) }

  it { is_expected.to validate_inclusion_of(:context_type).in_array(described_class::VALID_CONTEXT_TYPES) }
end
