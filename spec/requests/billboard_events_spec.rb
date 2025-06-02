require "rails_helper"
require "timecop" # Required for testing time-dependent logic

# /billboard_events and /bb_tabulations are aliases for the same controller

RSpec.describe "BillboardEvents" do
  let(:conversion_modifier) { 25 }

  let(:user) { create(:user, :trusted) }
  let(:organization) { create(:organization) }
  let(:billboard) { create(:billboard, organization_id: organization.id) }

  let(:base_event_params) do
    {
      billboard_id: billboard.id,
      context_type: BillboardEvent::CONTEXT_TYPE_HOME
    }
  end

  describe "POST /bb_tabulations" do
    before do
      sign_in user
      allow(ThrottledCall).to receive(:perform).and_yield
    end

    context "when creating an event" do
      it "creates a billboard impression event" do
        expect do
          post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
        end.to change(BillboardEvent, :count).by(1)
        expect(BillboardEvent.last.category).to eq("impression")
      end

      it "creates a billboard click event" do
        expect do
          post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "click") }
        end.to change(BillboardEvent, :count).by(1)
        expect(BillboardEvent.last.category).to eq("click")
      end

      it "assigns the event to the current user" do
        post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
        expect(BillboardEvent.last.user_id).to eq(user.id)
      end

      it "assigns the event to a passed article_id" do
        article = create(:article)
        post "/bb_tabulations", params: {
          billboard_event: base_event_params.merge(category: "impression", article_id: article.id)
        }
        expect(BillboardEvent.last.article_id).to eq(article.id)
      end

      it "assigns the event geolocation from headers" do
        post "/bb_tabulations", params: {
          billboard_event: base_event_params.merge(category: "impression")
        }, headers: { "X-Client-Geo" => "US-NY" }
        expect(BillboardEvent.last.geolocation).to eq("US-NY")
      end

      it "accepts legacy 'display_ad_event' params for backward compatibility" do
        expect do
          post "/bb_tabulations", params: {
            display_ad_event: {
              display_ad_id: billboard.id,
              context_type: BillboardEvent::CONTEXT_TYPE_HOME,
              category: "click"
            }
          }
        end.to change(BillboardEvent, :count).by(1)
        expect(billboard.reload.clicks_count).to eq(1)
      end
    end

    context "with billboard data tabulation" do
      context "when it is the first tabulation (counts_tabulated_at is nil)" do
        it "calculates and saves initial counts and success_rate from all historical events" do
          create_list(:billboard_event, 4, category: "impression", billboard: billboard)
          create_list(:billboard_event, 3, category: "click", billboard: billboard)

          post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "conversion") }
          billboard.reload

          total_clicks_value = 3 + (1 * conversion_modifier)
          total_impressions = 4
          expected_rate = total_clicks_value.to_f / total_impressions

          expect(billboard.impressions_count).to eq(4)
          expect(billboard.clicks_count).to eq(3)
          expect(billboard.success_rate).to eq(expected_rate)
          expect(billboard.counts_tabulated_at).to be_present
        end
      end

      context "when performing an incremental tabulation (counts_tabulated_at is present)" do
        let(:past_time) { 1.day.ago }

        before do
          Timecop.freeze(past_time) do
            billboard.update_columns(
              impressions_count: 100,
              clicks_count: 5,
              success_rate: 0.05,
              counts_tabulated_at: Time.current
            )
            create_list(:billboard_event, 10, category: "impression", billboard: billboard, created_at: Time.current)
          end
          create_list(:billboard_event, 20, category: "impression", billboard: billboard)
          create_list(:billboard_event, 2, category: "click", billboard: billboard)
        end

        it "updates counts and success_rate based only on new events" do
          post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "signup") }
          billboard.reload

          new_impressions = 20
          new_clicks = 2
          new_conversion_value = 1 * conversion_modifier

          total_impressions = 100 + new_impressions
          total_clicks = 5 + new_clicks
          total_clicks_value = total_clicks + new_conversion_value

          expected_rate = total_clicks_value.to_f / total_impressions

          expect(billboard.impressions_count).to eq(total_impressions)
          expect(billboard.clicks_count).to eq(total_clicks)
          expect(billboard.success_rate).to be_within(0.0001).of(expected_rate)
          expect(billboard.counts_tabulated_at).to be > past_time
        end
      end
    end

    context "with high-volume sampling logic" do
      it "skips update if impressions > 100k and rand(2) is 0" do
        billboard.update_columns(impressions_count: 100_001, counts_tabulated_at: 1.hour.ago)
        
        allow(Kernel).to receive(:rand).with(2).and_return(0)

        allow(Billboard).to receive(:find).with(billboard.id.to_s).and_return(billboard)
        expect(billboard).not_to receive(:update_columns)

        post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
      end

      xit "performs update if impressions > 100k and rand(2) is not 0" do
        billboard.update_columns(impressions_count: 100_001, counts_tabulated_at: 1.hour.ago)

        allow(Kernel).to receive(:rand).with(2).and_return(1)

        allow(Billboard).to receive(:find).with(billboard.id.to_s).and_return(billboard)
        expect(billboard).to receive(:update_columns).at_least(:once)

        post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
      end

      it "skips update if impressions > 500k and rand(3) is > 0" do
        billboard.update_columns(impressions_count: 500_001, counts_tabulated_at: 1.hour.ago)

        allow(Kernel).to receive(:rand).with(3).and_return(1)

        allow(Billboard).to receive(:find).with(billboard.id.to_s).and_return(billboard)
        expect(billboard).not_to receive(:update_columns)

        post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
      end

      xit "performs update if impressions > 500k and rand(3) is 0" do
        billboard.update_columns(impressions_count: 500_001, counts_tabulated_at: 1.hour.ago)
        
        # FIX: Stub BOTH rand calls to ensure the test is deterministic.
        # The first guard is made false by rand(3) returning 0.
        allow(Kernel).to receive(:rand).with(3).and_return(0)
        # The second guard is made false by rand(2) returning 1.
        allow(Kernel).to receive(:rand).with(2).and_return(1)

        allow(Billboard).to receive(:find).with(billboard.id.to_s).and_return(billboard)
        expect(billboard).to receive(:update_columns).at_least(:once)

        post "/bb_tabulations", params: { billboard_event: base_event_params.merge(category: "impression") }
      end
    end
  end
end