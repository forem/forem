require "rails_helper"

RSpec.describe Ahoy::Visit do
  let(:visit) { create(:ahoy_visit) }

  describe "validations" do
    describe "builtin validations" do
      subject { visit }

      it { is_expected.to have_many(:events).class_name("Ahoy::Event").dependent(:destroy) }
      it { is_expected.to belong_to(:user).optional }
    end
  end
end
