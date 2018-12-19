# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
require "rails_helper"

RSpec.describe ApiSecret, type: :model do
  describe "validations" do
    it { is_expected.to belong_to(:user) }
  end
end
# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
