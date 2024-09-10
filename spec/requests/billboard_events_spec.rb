require "rails_helper"

# /billboard_events and /bb_tabulations are aliases for the same controller

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
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CLICK
          }
        }
        expect(billboard.reload.clicks_count).to eq(1)
      end

      it "creates a billboard click event with old params" do
        post "/bb_tabulations", params: {
          display_ad_event: {
            display_ad_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CLICK
          }
        }
        expect(billboard.reload.clicks_count).to eq(1)
      end

      it "creates a billboard impression event" do
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION
          }
        }
        expect(billboard.reload.impressions_count).to eq(1)
      end

      it "creates a billboard conversion event" do
        # Create some impressions first
        create_list(:billboard_event, 1, billboard_id: billboard.id, category: BillboardEvent::CATEGORY_IMPRESSION)

        # Now create the conversion event
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CONVERSION
          }
        }

        expect(billboard.reload.success_rate).to eq(25)
      end

      it "creates a conversion category event when there has already been a signup event" do
        # Create some impressions first
        create_list(:billboard_event, 1, billboard_id: billboard.id, category: BillboardEvent::CATEGORY_IMPRESSION)
        # Create the signup event
        create(:billboard_event, billboard_id: billboard.id, category: BillboardEvent::CATEGORY_SIGNUP)

        # Now create the conversion event
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_CONVERSION
          }
        }

        expect(billboard.reload.success_rate).to eq(50)
      end

      it "creates a billboard success rate with conversion" do
        ad_event_params = { billboard_id: billboard.id, context_type: BillboardEvent::CONTEXT_TYPE_HOME }
        impression_params = ad_event_params.merge(category: BillboardEvent::CATEGORY_IMPRESSION, user: user)
        click_params = ad_event_params.merge(category: BillboardEvent::CATEGORY_CLICK, user: user)
        create_list(:billboard_event, 4, impression_params)
        create_list(:billboard_event, 3, click_params)

        post(
          "/bb_tabulations",
          params: { billboard_event: ad_event_params.merge(category: BillboardEvent::CATEGORY_CONVERSION) },
        )

        # Success rate should be (3 clicks + 25 from conversion) / 4 impressions = 7
        expect(billboard.reload.success_rate).to eq(7)
      end

      it "accounts for signups in the success rate" do
        ad_event_params = { billboard_id: billboard.id, context_type: BillboardEvent::CONTEXT_TYPE_HOME }
        impression_params = ad_event_params.merge(category: BillboardEvent::CATEGORY_IMPRESSION, user: user)
        click_params = ad_event_params.merge(category: BillboardEvent::CATEGORY_CLICK, user: user)
        create_list(:billboard_event, 3, click_params)
        create_list(:billboard_event, 4, impression_params)

        post(
          "/bb_tabulations",
          params: { billboard_event: ad_event_params.merge(category: BillboardEvent::CATEGORY_SIGNUP) },
        )

        # 28 / 4 = 7 -> because 3 clicks and one signup is 28 (signup worth 25 clicks)
        expect(billboard.reload.success_rate).to eq(7)
      end

      it "assigns event to current user" do
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION
          }
        }
        expect(BillboardEvent.last.user_id).to eq(user.id)
      end

      it "assigns event to passed article_id" do
        article = create(:article)
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION,
            article_id: article.id
          }
        }
        expect(BillboardEvent.last.article_id)
          .to eq(article.id)
      end

      it "assigns event to passed current geolocation" do
        article = create(:article)
        post "/bb_tabulations", params: {
          billboard_event: {
            billboard_id: billboard.id,
            context_type: BillboardEvent::CONTEXT_TYPE_HOME,
            category: BillboardEvent::CATEGORY_IMPRESSION,
            article_id: article.id
          }
        }, headers: { "X-Client-Geo" => "CA-AB", "X-Cacheable-Client-Geo" => "CA" }
        expect(BillboardEvent.last.geolocation).to eq("CA-AB")
      end

      it "uses a ThrottledCall for data updates" do
        post "/bb_tabulations", params: {
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
