require "rails_helper"

RSpec.describe FeedEvent do
  describe "validations" do
    it { is_expected.to belong_to(:article).optional }
    it { is_expected.to validate_numericality_of(:article_id).only_integer }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to validate_numericality_of(:user_id).only_integer.allow_nil }

    it { is_expected.to define_enum_for(:category).with_values(%i[impression click reaction comment]) }
    it { is_expected.to validate_numericality_of(:article_position).is_greater_than(0).only_integer }
    it { is_expected.to validate_inclusion_of(:context_type).in_array(%w[home search tag]) }
  end
end
