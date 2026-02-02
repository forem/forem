require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20251108101300_backfill_billboard_placement_area_config_selection_weights.rb",
)

describe DataUpdateScripts::BackfillBillboardPlacementAreaConfigSelectionWeights do
  it "backfills selection_weights for configs without them" do
    config = BillboardPlacementAreaConfig.create!(
      placement_area: "sidebar_left",
      signed_in_rate: 50,
      signed_out_rate: 50,
      selection_weights: {}
    )

    expect(config.selection_weights).to be_empty

    described_class.new.run

    config.reload
    expect(config.selection_weights).not_to be_empty
    expect(config.selection_weights.keys).to include("random_selection", "new_and_priority", "new_only", "weighted_performance")
  end

  it "does not overwrite existing selection_weights" do
    existing_weights = {
      "random_selection" => 15,
      "new_and_priority" => 25,
      "new_only" => 10,
      "weighted_performance" => 50
    }

    config = BillboardPlacementAreaConfig.create!(
      placement_area: "sidebar_left",
      signed_in_rate: 50,
      signed_out_rate: 50,
      selection_weights: existing_weights
    )

    described_class.new.run

    config.reload
    expect(config.selection_weights).to eq(existing_weights)
  end

  it "handles errors gracefully and continues processing other configs" do
    config1 = BillboardPlacementAreaConfig.create!(
      placement_area: "sidebar_left",
      signed_in_rate: 50,
      signed_out_rate: 50,
      selection_weights: {}
    )

    config2 = BillboardPlacementAreaConfig.create!(
      placement_area: "feed_first",
      signed_in_rate: 75,
      signed_out_rate: 75,
      selection_weights: {}
    )

    # Mock one config to raise an error
    allow_any_instance_of(BillboardPlacementAreaConfig).to receive(:initialize_weights_from_app_config)
      .and_call_original
    allow(config1).to receive(:initialize_weights_from_app_config).and_raise(StandardError.new("Test error"))
    allow(BillboardPlacementAreaConfig).to receive(:find_each).and_yield(config1).and_yield(config2)

    expect(Rails.logger).to receive(:warn).with(/Failed to initialize weights/)

    described_class.new.run

    # config2 should still be processed despite config1 erroring
    config2.reload
    expect(config2.selection_weights).not_to be_empty
  end

  it "skips configs that already have non-empty selection_weights" do
    config = BillboardPlacementAreaConfig.create!(
      placement_area: "sidebar_left",
      signed_in_rate: 50,
      signed_out_rate: 50,
      selection_weights: { "random_selection" => 10 }
    )

    expect(config).not_to receive(:initialize_weights_from_app_config)

    described_class.new.run
  end
end

