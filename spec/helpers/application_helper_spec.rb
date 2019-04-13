require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#community_qualified_name" do
    it "equals to the full qualified community name" do
      expected_name = "The #{ApplicationConfig['COMMUNITY_NAME']} Community"
      expect(helper.community_qualified_name).to eq(expected_name)
    end
  end
end
