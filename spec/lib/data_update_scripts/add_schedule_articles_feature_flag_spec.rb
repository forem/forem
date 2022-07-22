require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220613093333_add_schedule_articles_feature_flag.rb",
)

describe DataUpdateScripts::AddScheduleArticlesFeatureFlag do
  after do
    FeatureFlag.remove(:schedule_articles)
  end

  it "adds the :schedule_articles flag" do
    expect do
      described_class.new.run
    end.to change { FeatureFlag.exist?(:schedule_articles) }.from(false).to(true)
  end

  it "works if the flag is already available" do
    FeatureFlag.add(:schedule_articles)

    expect do
      described_class.new.run
    end.not_to change { FeatureFlag.exist?(:schedule_articles) }
  end
end
