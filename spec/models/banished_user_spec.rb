require "rails_helper"

RSpec.describe BanishedUser, type: :model do
  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    end
  end
end
