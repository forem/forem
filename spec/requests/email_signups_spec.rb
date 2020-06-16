require "rails_helper"

RSpec.describe "EmailSignups", type: :request do
  let(:article) { create(:article) }

  describe "will you work...please?" do
    it "just work...please!!" do
      expect(true).to eq true
    end
  end
end
