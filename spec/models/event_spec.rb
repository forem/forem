require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:organization).optional }
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:type_of).with_values(
        live_stream: 0,
        takeover: 1,
        other: 2
      )
    end
  end
end
