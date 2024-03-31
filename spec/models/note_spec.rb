require "rails_helper"

RSpec.describe Note do
  it { is_expected.to belong_to(:noteable) }
  it { is_expected.to belong_to(:author).class_name("User").optional }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:reason) }
end
