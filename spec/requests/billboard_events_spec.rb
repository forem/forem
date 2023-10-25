require "rails_helper"

RSpec.describe "BillboardEvents" do
  let(:user) { create(:user, :trusted) }
  let(:organization) { create(:organization) }
  let(:billboard) { create(:billboard, organization_id: organization.id) }

  describe "POST /billboard_events", :throttled_call do
    context "when user signed in" do
      before do
        sign_in user
      end

      it "creates a billboard click event" do
        post "/billboard_events", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CLICK
          }
        }
        expect(billboard.reload.clicks_count).to eq(1)
      end

      it "creates a billboard click event with old params" do
        post "/billboard_events", params: {
          display_ad_event: {
            display_ad_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CLICK
          }
        }
        expect(billboard.reload.clicks_count).to eq(1)
      end

      it "creates a billboard impression event" do
        post "/billboard_events", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION
          }
        }
        expect(billboard.reload.impressions_count).to eq(1)
      end

      it "creates a billboard success rate" do
        ad_event_params = { billboard_id: billboard.id, context_type: BillboardEvent::CONTEXT_TYPE_HOME }
        impression_params = ad_event_params.merge(category: BillboardEvent::CATEGORY_IMPRESSION, user: user)
        create_list(:billboard_event, 4, impression_params)

        post(
          "/billboard_events",
          params: { billboard_event: ad_event_params.merge(category: BillboardEvent::CATEGORY_CLICK) },
        )

        expect(billboard.reload.success_rate).to eq(0.25)
      end

      it "assigns event to current user" do
        post "/billboard_events", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION
          }
        }
        expect(BillboardEvent.last.user_id).to eq(user.id)
      end

      it "uses a ThrottledCall for data updates" do
        post "/billboard_events", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION
          }
        }

        expect(ThrottledCall).to have_received(:perform)
          .with("billboards_data_update-#{billboard.id}", throttle_for: instance_of(ActiveSupport::Duration))
      end
    end
  end
end
