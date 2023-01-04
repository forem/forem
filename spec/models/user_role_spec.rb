require "rails_helper"

RSpec.describe UserRole do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:role) }
end
