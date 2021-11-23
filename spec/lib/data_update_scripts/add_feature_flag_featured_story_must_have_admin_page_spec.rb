require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211121235419_add_feature_flag_featured_story_must_have_admin_page.rb",
)

describe DataUpdateScripts::AddFeatureFlagFeaturedStoryMustHaveAdminPage do
  after do
    FeatureFlag.remove(:featured_story_must_have_main_image)
  end

  it "adds the :featured_story_must_have_main_image flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:featured_story_must_have_main_image) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:featured_story_must_have_main_image)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:featured_story_must_have_main_image) }
  end
end
