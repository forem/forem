require "rails_helper"

RSpec.describe PollTag, type: :liquid_tag do
  describe ".user_authorization_method_name" do
    subject(:result) { described_class.user_authorization_method_name }

    it { is_expected.to eq(:any_admin?) }
  end

  describe ".script" do
    it "escapes HTML in poll option text before inserting into innerHTML" do
      expect(described_class.script).to include("escapedOptionText")
      expect(described_class.script).to include(".replace(/</g, '&lt;')")
    end
  end
end
