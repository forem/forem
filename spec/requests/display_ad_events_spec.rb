require "rails_helper"

RSpec.describe "DisplayAdEvents", type: :request do
  let(:user) { create(:user, :trusted) }
  let(:organization) { create(:organization) }
  let(:display_ad) { create(:display_ad, organization_id: organization.id) }

  describe "POST /display_ad_events", throttled_call: true do
    context "when user signed in" do
      before do
        sign_in user
      end

      it "creates a display ad click event" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: DisplayAdEvent::CONTEXT_TYPE_HOME,
            category: DisplayAdEvent::CATEGORY_CLICK
          }
        }
        expect(display_ad.reload.clicks_count).to eq(1)
      end

      it "creates a display ad impression event" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: DisplayAdEvent::CONTEXT_TYPE_HOME,
            category: DisplayAdEvent::CATEGORY_IMPRESSION
          }
        }
        expect(display_ad.reload.impressions_count).to eq(1)
      end

      it "creates a display ad success rate" do
        ad_event_params = { display_ad_id: display_ad.id, context_type: DisplayAdEvent::CONTEXT_TYPE_HOME }
        impression_params = ad_event_params.merge(category: DisplayAdEvent::CATEGORY_IMPRESSION, user: user)
        create_list(:display_ad_event, 4, impression_params)

        post(
          "/display_ad_events",
          params: { display_ad_event: ad_event_params.merge(category: DisplayAdEvent::CATEGORY_CLICK) },
        )

        expect(display_ad.reload.success_rate).to eq(0.25)
      end

      it "assigns event to current user" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: DisplayAdEvent::CONTEXT_TYPE_HOME,
            category: DisplayAdEvent::CATEGORY_IMPRESSION
          }
        }
        expect(DisplayAdEvent.last.user_id).to eq(user.id)
      end

      it "uses a ThrottledCall for data updates" do
        post "/display_ad_events", params: {
          display_ad_event: {
            display_ad_id: display_ad.id,
            context_type: DisplayAdEvent::CONTEXT_TYPE_HOME,
            category: DisplayAdEvent::CATEGORY_IMPRESSION
          }
        }

        expect(ThrottledCall).to have_received(:perform)
          .with(:display_ads_data_update, throttle_for: instance_of(ActiveSupport::Duration))
      end
    end
  end
end
