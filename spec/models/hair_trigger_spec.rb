require "rails_helper"

# HairTrigger suggests adding this test to make sure the schema and triggers are aligned
# See https://github.com/jenseng/hair_trigger#testing
RSpec.describe HairTrigger, type: :model do
  describe ".migrations_current?" do
    # Disabled due to Rails 7 compatibility. See https://github.com/jenseng/hair_trigger/pull/104
    xit "is always true" do
      # work-around empty AR::Base descendants array caused by with_model cleanup
      # HairTrigger uses AR::Base to get database triggers (and compare against the schema)
      if ActiveRecord::Base.descendants.blank?
        ActiveSupport::DescendantsTracker.store_inherited(ActiveRecord::Base, ApplicationRecord)
      end

      expect(described_class.migrations_current?).to be(true)
    end
  end
end
