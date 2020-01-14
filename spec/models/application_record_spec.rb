require "rails_helper"

# ApplicationRecord is an abstract class, tests will use one of the core models
RSpec.describe ApplicationRecord, type: :model do
  describe ".estimated_count" do
    it "does not raise errors if there are no rows" do
      expect { User.estimated_count }.not_to raise_error
    end
  end
end
