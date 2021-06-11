require "rails_helper"

# HairTrigger suggests adding this test to make sure the schema and triggers are aligned
# See https://github.com/jenseng/hair_trigger#testing
RSpec.describe HairTrigger, type: :model do
  describe ".migrations_current?" do
    it "is always true" do
      expect(described_class.migrations_current?).to be(true)
    end
  end
end
