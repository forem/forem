require "rails_helper"

RSpec.describe HtmlVariantTrial, type: :model do
  it { is_expected.to validate_presence_of(:html_variant_id) }
  it { is_expected.to belong_to(:html_variant) }
  it { is_expected.to belong_to(:article).optional }
end
