require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20260223130700_verify_tagging_counts.rb",
)

RSpec.describe DataUpdateScripts::VerifyTaggingCounts do
  let(:tag1) { create(:tag) }
  let(:tag2) { create(:tag) }

  it "identifies tags with mismatched counts" do
    # Create articles with tags to establish correct counts
    create(:article, tags: tag1.name)
    create(:article, tags: tag1.name)
    create(:article, tags: tag2.name)

    # Manually break the counter cache using SQL to bypass readonly protection
    ActiveRecord::Base.connection.execute("UPDATE tags SET taggings_count = 5 WHERE id = #{tag1.id}")
    tag1.reload

    expect { described_class.new.run }.to output(/Tags with mismatched counts: 1/).to_stdout
  end

  it "reports no issues when all counts are accurate" do
    create(:article, tags: tag1.name)
    create(:article, tags: tag2.name)

    expect { described_class.new.run }.to output(/All tag counts are accurate/).to_stdout
  end

  it "handles tags with zero taggings" do
    # Tag with no articles
    tag1

    expect { described_class.new.run }.to output(/All tag counts are accurate/).to_stdout
  end
end
