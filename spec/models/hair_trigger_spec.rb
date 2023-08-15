require "rails_helper"

# HairTrigger suggests adding this test to make sure the schema and triggers are aligned
# See https://github.com/jenseng/hair_trigger#testing
RSpec.describe HairTrigger do
  describe ".migrations_current?" do
    it "is always true" do
      # work-around empty AR::Base descendants array caused by with_model cleanup
      # HairTrigger uses AR::Base to get database triggers (and compare against the schema)
      if ActiveRecord::Base.descendants.blank?
        ActiveSupport::DescendantsTracker.store_inherited(ActiveRecord::Base, ApplicationRecord)
      end
      p "current migrations:"
      p described_class.current_migrations.map(&:last).sort

      p "current_triggers:"
      p described_class.current_triggers.sort

      expect(described_class.migrations_current?).to be(true)
    end
  end
end
