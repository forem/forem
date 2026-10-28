require "rails_helper"

RSpec.describe CiKnapsackProSkipShallowFetch do
  it "overrides shallow_repository? to return false so KnapsackPro skips shallow git fetches" do
    adapter_class = Class.new do
      def shallow_repository?
        true
      end
    end
    adapter_class.prepend(described_class)

    expect(adapter_class.new.shallow_repository?).to be(false)
  end

  if ENV["CI"]
    it "prepends the override to KnapsackPro's GitAdapter" do
      expect(KnapsackPro::RepositoryAdapters::GitAdapter.ancestors).to include(described_class)
    end
  end
end
