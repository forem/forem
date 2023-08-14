require "rails_helper"

RSpec.describe FeedEvent do
  describe "validations" do
    it { is_expected.to belong_to(:article) }
    it { is_expected.to belong_to(:user).optional }

    it { is_expected.to define_enum_for(:category).with_values(%i[impression click]) }
  end
end
