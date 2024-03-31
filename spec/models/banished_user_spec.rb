require "rails_helper"

RSpec.describe BanishedUser do
  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to belong_to(:banished_by).class_name("User").optional }
      it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    end
  end
end
